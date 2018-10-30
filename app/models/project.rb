require 'base64'

class Project < ActiveRecord::Base
  include Autostart
  include Owner
  include UrlHelper
  include EventLoggable
  include Project::DefaultBranch
  include Project::Finders
  include Project::GithubApi
  include Project::MassCreate

  VISIBILITIES = ['open', 'hidden']
  MAX_OWN_PROJECTS = 32000
  NAME_REGEXP = /[\w\-\+\.]+/
  OWNER_AND_NAME_REGEXP = /#{User::NAME_REGEXP.source}\/#{NAME_REGEXP.source}/
  self.per_page = 25

  belongs_to :owner, polymorphic: true, counter_cache: :own_projects_count
  belongs_to :maintainer, class_name: 'User'

  has_many :project_to_repositories, dependent: :destroy
  has_many :repositories, through: :project_to_repositories
  has_many :project_statistics, dependent: :destroy

  has_many :build_lists, dependent: :destroy

  has_many :relations, as: :target, dependent: :destroy
  has_many :groups,        through: :relations, source: :actor, source_type: 'Group'

  has_many :packages, class_name: 'BuildList::Package', dependent: :destroy

  validates :name, uniqueness: { scope: [:owner_id, :owner_type], case_sensitive: false },
                   presence: true,
                   format: { with: /\A#{NAME_REGEXP.source}\z/,
                             message: I18n.t("activerecord.errors.project.uname") },
                   length: { maximum: 100 }
  validates :maintainer, presence: true, unless: :new_record?
  validates :url, presence: true, format: { with: /\Ahttps?:\/\/[\S]+\z/ }, if: :mass_import or :mass_create
  validates :add_to_repository_id, presence: true, if: :mass_import or :mass_create
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
  validate { errors.add(:base, :can_have_less_or_equal, count: MAX_OWN_PROJECTS) if owner.projects.size >= MAX_OWN_PROJECTS }
  # throws validation error message from ProjectToRepository model into Project model
  validate do |project|
    project.project_to_repositories.each do |p_to_r|
      next if p_to_r.valid?
      p_to_r.errors.full_messages.each{ |msg| errors[:base] << msg }
    end
    errors.delete :project_to_repositories
  end

  attr_readonly :owner_id, :owner_type

  before_validation :truncate_name, on: :create
  before_save -> { self.owner_uname = owner.uname if owner_uname.blank? || owner_id_changed? || owner_type_changed? }
  before_create :set_maintainer
  after_save :attach_to_personal_repository

  attr_accessor :url, :srpms_list, :mass_import, :add_to_repository_id, :mass_create

  def init_mass_import
    Project.perform_later :low, :run_mass_import, url, srpms_list, visibility, owner, add_to_repository_id
  end

  def init_mass_create
    Project.perform_later :low, :run_mass_create, url, visibility, owner, add_to_repository_id
  end

  def name_with_owner
    "#{owner_uname || owner.uname}/#{name}"
  end

  def to_param
    name_with_owner
  end

  def all_members(*includes)
    members(includes) | (owner_type == 'User' ? [owner] : owner.members.includes(includes))
  end

  def members(*includes)
    groups.map{ |g| g.members.includes(includes) }.flatten
  end

  def platforms
    @platforms ||= repositories.map(&:platform).uniq
  end

  def admins
    admins = self.collaborators.where("relations.role = 'admin'")
    grs = self.groups.where("relations.role = 'admin'")
    if self.owner.is_a? Group
      grs = grs.where("relations.actor_id != ?", self.owner.id)
      admins = admins | owner.members.where("relations.role = 'admin'")
    end
    admins = admins | grs.map(&:members).flatten # member of the admin group is admin
  end

  def public?
    visibility == 'open'
  end

  def owner?(user)
    owner == user
  end

  def git_project_address
    "git://github.com/" + github_get_organization + "/" + name + ".git"
  end

  def build_for(mass_build, repository_id, project_version, arch =  Arch.find_by(name: 'i586'), priority = 0)
    build_for_platform  = mass_build.build_for_platform
    save_to_platform    = mass_build.save_to_platform
    user                = mass_build.user
    # Select main and project platform repository(contrib, non-free and etc)
    # If main does not exist, will connect only project platform repository
    # If project platform repository is main, only main will be connect
    main_rep_id = build_for_platform.repositories.main.first.try(:id)
    include_repos = ([main_rep_id] << (save_to_platform.main? ? repository_id : nil)).compact.uniq

    build_list = build_lists.build do |bl|
      bl.save_to_platform               = save_to_platform
      bl.build_for_platform             = build_for_platform
      bl.arch                           = arch
      bl.project_version                = project_version
      bl.user                           = user
      bl.auto_publish_status            = mass_build.auto_publish_status
      bl.auto_create_container          = mass_build.auto_create_container
      bl.include_repos                  = include_repos
      bl.extra_repositories             = mass_build.extra_repositories
      bl.extra_build_lists              = mass_build.extra_build_lists
      bl.priority                       = priority
      bl.mass_build_id                  = mass_build.id
      bl.save_to_repository_id          = repository_id
      bl.include_testing_subrepository  = mass_build.include_testing_subrepository?
      bl.use_cached_chroot              = mass_build.use_cached_chroot?
      bl.use_extra_tests                = mass_build.use_extra_tests?
      bl.external_nodes                 = mass_build.external_nodes
    end
    build_list.save
  end

  def archive_by_treeish_and_format(treeish, format)
    @archive ||= create_archive treeish, format
  end

  # Finds release tag and increase its:
  # 'Release: %mkrel 4mdk' => 'Release: 5mdk'
  # 'Release: 4' => 'Release: 5'
  # Finds release macros and increase it:
  # '%define release %mkrel 4mdk' => '%define release 5mdk'
  # '%define release 4' => '%define release 5'
  def self.replace_release_tag(content)

    build_new_release = Proc.new do |release, combine_release|
      if combine_release.present?
        r = combine_release.split('.').last.to_i
        release << combine_release.gsub(/.[\d]+$/, '') << ".#{r + 1}"
      else
        release = release.to_i + 1
      end
      release
    end

    content.gsub(/^Release:(\s+)(%mkrel\s+)?(\d+)([.\d]+)?(mdk)?$/) do |line|
      tab, mkrel, mdk = $1, $2, $5
      "Release:#{tab}#{build_new_release.call($3, $4)}#{mdk}"
    end.gsub(/^%define\s+release:?(\s+)(%mkrel\s+)?(\d+)([.\d]+)?(mdk)?$/) do |line|
      tab, mkrel, mdk = $1, $2, $5
      "%define release#{tab}#{build_new_release.call($3, $4)}#{mdk}"
    end
  end

  class << self
    Autostart::HUMAN_AUTOSTART_STATUSES.each do |autostart_status, human_autostart_status|
      define_method "autostart_build_lists_#{human_autostart_status}" do
        autostart_build_lists autostart_status
      end
    end
  end

  def self.autostart_build_lists(autostart_status)
    Project.where(autostart_status: autostart_status).find_each do |p|
      p.project_to_repositories.autostart_enabled.includes(repository: :platform).each do |p_to_r|
        repository  = p_to_r.repository
        user        = User.find(p_to_r.user_id)
        if repository.platform.personal?
          platforms = Platform.availables_main_platforms(user)
        else
          platforms = [repository.platform]
        end
        platforms.each do |platform|
          platform.platform_arch_settings.by_default.pluck(:arch_id).each do |arch_id|
            build_list = p.build_lists.build do |bl|
              bl.save_to_platform       = repository.platform
              bl.build_for_platform     = platform
              bl.arch_id                = arch_id
              bl.project_version        = p.project_version_for(repository.platform, platform)
              bl.user                   = user
              bl.auto_publish_status    = p_to_r.auto_publish? ? BuildList::AUTO_PUBLISH_STATUS_DEFAULT : BuildList::AUTO_PUBLISH_STATUS_NONE
              bl.save_to_repository     = repository
              bl.include_repos          = [platform.repositories.main.first.try(:id)].compact
              if repository.platform.personal?
                bl.extra_repositories   = [repository.id]
              else
                bl.include_repos       |= [repository.id]
              end
            end
            build_list.save
          end
        end
      end
    end
  end

  def increase_release_tag(project_version, message)
    begin
      file = Github_blobs_api.contents github_get_organization + '/' + name, path: '/' + name + '.spec', ref: project_version
    rescue => e
      Raven.capture_exception(e)
      return false
    end
    if file
      begin
        decoded_content = Base64.decode64(file.content)
        new_content = Project.replace_release_tag decoded_content
        return if new_content == decoded_content
        Github_blobs_api.update_contents github_get_organization + '/' + name, name + '.spec',\
                              message, file.sha, new_content, branch: project_version
      rescue => e
        Raven.capture_message(e)
        return false
      end
    end
    return true
  end

  protected

  def create_archive(treeish, format)
    file_name = "#{name}-#{treeish}"
    fullname  = "#{file_name}.#{tag_file_format(format)}"
    file = Tempfile.new fullname,  File.join(Rails.root, 'tmp')
    system("cd #{path}; git archive --format=#{format == 'zip' ? 'zip' : 'tar'} --prefix=#{file_name}/ #{treeish} #{format == 'zip' ? '' : ' | gzip -9'} > #{file.path}")
    file.close
    {
      path:     file.path,
      fullname: fullname
    }
  end

  def tag_file_format(format)
    format == 'zip' ? 'zip' : 'tar.gz'
  end

  def truncate_name
    self.name = name.strip if name
  end

  def attach_to_personal_repository
    owner_repos = self.owner.personal_platform.repositories
    if is_package
      repositories << self.owner.personal_repository unless repositories.exists?(id: owner_repos.pluck(:id))
    else
      repositories.delete owner_repos
    end
  end

  def set_maintainer
    if maintainer_id.blank?
      self.maintainer_id = (owner_type == 'User') ? self.owner_id : self.owner.owner_id
    end
  end

end
