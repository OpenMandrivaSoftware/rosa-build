class BuildList < ActiveRecord::Base
  include Modules::Models::CommitAndVersion
  include Modules::Models::FileStoreClean
  include AbfWorker::ModelHelper
  include Modules::Observers::ActivityFeed::BuildList

  belongs_to :project
  belongs_to :arch
  belongs_to :save_to_platform,   class_name: 'Platform'
  belongs_to :save_to_repository, class_name: 'Repository'
  belongs_to :build_for_platform, class_name: 'Platform'
  belongs_to :user
  belongs_to :builder,    class_name: 'User'
  belongs_to :publisher,  class_name: 'User'
  belongs_to :advisory
  belongs_to :mass_build, counter_cache: true
  has_many :items, class_name: '::BuildList::Item', dependent: :destroy
  has_many :packages, class_name: '::BuildList::Package', dependent: :destroy
  has_many :source_packages, class_name: '::BuildList::Package', conditions: {package_type: 'source'}

  UPDATE_TYPES = %w[bugfix security enhancement recommended newpackage]
  RELEASE_UPDATE_TYPES = %w[bugfix security]
  EXTRA_PARAMS = %w[cfg_options cfg_urpm_options build_src_rpm build_rpm]
  EXTERNAL_NODES = %w[owned everything]

  AUTO_PUBLISH_STATUS_NONE    = 'none'
  AUTO_PUBLISH_STATUS_DEFAULT = 'default'
  AUTO_PUBLISH_STATUS_TESTING = 'testing'
  AUTO_PUBLISH_STATUSES = [AUTO_PUBLISH_STATUS_NONE, AUTO_PUBLISH_STATUS_DEFAULT, AUTO_PUBLISH_STATUS_TESTING]

  validates :project_id, :project_version, :arch, :include_repos,
            :build_for_platform_id, :save_to_platform_id, :save_to_repository_id, presence: true
  validates_numericality_of :priority, greater_than_or_equal_to: 0
  validates :external_nodes, inclusion: {in:  EXTERNAL_NODES}, allow_blank: true
  validates :auto_publish_status, inclusion: {in: AUTO_PUBLISH_STATUSES}
  validates :update_type, inclusion: UPDATE_TYPES,
            unless: Proc.new { |b| b.advisory.present? }
  validates :update_type, inclusion: {in: RELEASE_UPDATE_TYPES, message: I18n.t('flash.build_list.frozen_platform')},
            if: Proc.new { |b| b.advisory.present? }
  validate lambda {
    errors.add(:build_for_platform, I18n.t('flash.build_list.wrong_platform')) if save_to_platform.main? && save_to_platform_id != build_for_platform_id
  }
  validate lambda {
    errors.add(:build_for_platform, I18n.t('flash.build_list.wrong_build_for_platform')) unless build_for_platform.main?
  }
  validate lambda {
    errors.add(:save_to_repository, I18n.t('flash.build_list.wrong_repository')) if save_to_repository.platform_id != save_to_platform.id
  }
  validate lambda {
    errors.add(:save_to_repository, I18n.t('flash.build_list.wrong_include_repos')) if build_for_platform.repositories.where(id: include_repos).count != include_repos.size
  }
  validate lambda {
    errors.add(:save_to_repository, I18n.t('flash.build_list.wrong_project')) unless save_to_repository.projects.exists?(project_id)
  }
  before_validation lambda { self.include_repos = include_repos.uniq if include_repos.present? }, on: :create
  before_validation :prepare_extra_repositories,  on: :create
  before_validation :prepare_extra_build_lists,   on: :create
  before_validation :prepare_extra_params,        on: :create
  before_validation :prepare_auto_publish_status, on: :create

  attr_accessible :include_repos, :auto_publish, :build_for_platform_id, :commit_hash,
                  :arch_id, :project_id, :save_to_repository_id, :update_type,
                  :save_to_platform_id, :project_version, :auto_create_container,
                  :extra_repositories, :extra_build_lists, :extra_params, :external_nodes,
                  :include_testing_subrepository, :auto_publish_status

  LIVE_TIME     = 4.week  # for unpublished
  MAX_LIVE_TIME = 3.month # for published
  STATUSES, HUMAN_STATUSES = [], {}
  [
    %w(SUCCESS                        0),
    # %w(ERROR                          1),
    # %w(PROJECT_SOURCE_ERROR           6),
    # %w(DEPENDENCIES_ERROR             555),
    %w(BUILD_ERROR                    666),
    %w(BUILD_STARTED                  3000),
    %w(BUILD_CANCELED                 5000),
    %w(WAITING_FOR_RESPONSE           4000),
    %w(BUILD_PENDING                  2000),
    %w(BUILD_PUBLISHED                6000),
    %w(BUILD_PUBLISH                  7000),
    %w(FAILED_PUBLISH                 8000),
    %w(REJECTED_PUBLISH               9000),
    %w(BUILD_CANCELING                10000),
    %w(TESTS_FAILED                   11000),
    %w(BUILD_PUBLISHED_INTO_TESTING   12000),
    %w(BUILD_PUBLISH_INTO_TESTING     13000),
    %w(FAILED_PUBLISH_INTO_TESTING    14000)
  ].each do |kind, value|
    value = value.to_i
    const_set kind, value
    STATUSES << value
    HUMAN_STATUSES[value] = kind.downcase.to_sym
  end
  STATUSES.freeze
  HUMAN_STATUSES.freeze

  scope :recent, order("#{table_name}.updated_at DESC")
  scope :for_extra_build_lists, lambda {|ids, current_ability, save_to_platform|
    s = scoped
    s = s.where(id: ids).published_container.accessible_by(current_ability, :read)
    s = s.where(save_to_platform_id: save_to_platform.id) if save_to_platform && save_to_platform.main?
    s
  }
  scope :for_status, lambda {|status| where(status: status) if status.present? }
  scope :for_user, lambda { |user| where(user_id: user.id)  }
  scope :not_owned_external_nodes, where("#{table_name}.external_nodes is null OR #{table_name}.external_nodes != ?", :owned)
  scope :external_nodes, lambda { |type| where("#{table_name}.external_nodes = ?", type) }
  scope :oldest, lambda { where("#{table_name}.updated_at < ?", Time.zone.now - 15.seconds) }
  scope :for_platform, lambda { |platform| where(build_for_platform_id: platform)  }
  scope :by_mass_build, lambda { |mass_build| where(mass_build_id: mass_build) }
  scope :scoped_to_arch, lambda {|arch| where(arch_id: arch) if arch.present? }
  scope :scoped_to_save_platform, lambda {|pl_id| where(save_to_platform_id: pl_id) if pl_id.present? }
  scope :scoped_to_project_version, lambda {|project_version| where(project_version: project_version) if project_version.present? }
  scope :scoped_to_is_circle, lambda {|is_circle| where(is_circle: is_circle) }
  scope :for_creation_date_period, lambda{|start_date, end_date|
    s = scoped
    s = s.where(["#{table_name}.created_at >= ?", start_date]) if start_date
    s = s.where(["#{table_name}.created_at <= ?", end_date]) if end_date
    s
  }
  scope :for_notified_date_period, lambda{|start_date, end_date|
    s = scoped
    s = s.where("#{table_name}.updated_at >= ?", start_date)  if start_date.present?
    s = s.where("#{table_name}.updated_at <= ?", end_date)    if end_date.present?
    s
  }
  scope :scoped_to_project_name, lambda {|project_name| joins(:project).where('projects.name LIKE ?', "%#{project_name}%") if project_name.present? }
  scope :scoped_to_new_core, lambda {|new_core| where(new_core: new_core)}
  scope :outdated, where("#{table_name}.created_at < ? AND #{table_name}.status NOT IN (?) OR #{table_name}.created_at < ?", Time.now - LIVE_TIME, [BUILD_PUBLISHED,BUILD_PUBLISHED_INTO_TESTING], Time.now - MAX_LIVE_TIME)
  scope :published_container, where(container_status: BUILD_PUBLISHED)

  serialize :additional_repos
  serialize :include_repos
  serialize :results, Array
  serialize :extra_repositories,  Array
  serialize :extra_build_lists,   Array
  serialize :extra_params,        Hash

  after_commit  :place_build, on: :create
  after_destroy :remove_container

  state_machine :status, initial: :waiting_for_response do

    # WTF? around_transition -> infinite loop
    before_transition do |build_list, transition|
      status = HUMAN_STATUSES[build_list.status]
      if build_list.mass_build && MassBuild::COUNT_STATUSES.include?(status)
        MassBuild.decrement_counter "#{status.to_s}_count", build_list.mass_build_id
      end
    end

    after_transition do |build_list, transition|
      status = HUMAN_STATUSES[build_list.status]
      if build_list.mass_build && MassBuild::COUNT_STATUSES.include?(status)
        MassBuild.increment_counter "#{status.to_s}_count", build_list.mass_build_id
      end
    end

    after_transition(on: :place_build) do |build_list, transition|
      build_list.add_job_to_abf_worker_queue if build_list.external_nodes.blank?
    end
    after_transition on: :published,
      do: [:set_version_and_tag, :actualize_packages]
    after_transition on: :publish, do: :set_publisher
    after_transition(on: :publish) do |build_list, transition|
      if transition.from == BUILD_PUBLISHED_INTO_TESTING
        build_list.cleanup_packages_from_testing
      end
    end
    after_transition on: :cancel, do: :cancel_job

    after_transition on: [:published, :fail_publish, :build_error, :tests_failed], do: :notify_users
    after_transition on: :build_success, do: :notify_users,
      unless: lambda { |build_list| build_list.auto_publish? || build_list.auto_publish_into_testing? }

    event :place_build do
      transition waiting_for_response: :build_pending
    end

    event :start_build do
      transition build_pending: :build_started
    end

    event :cancel do
      transition [:build_pending, :build_started] => :build_canceling
    end

    # build_canceling: :build_canceled - canceling from UI
    # build_started: :build_canceled - canceling from worker by time-out (time_living has been expired)
    event :build_canceled do
      transition [:build_canceling, :build_started] => :build_canceled
    end

    event :published do
      transition [:build_publish, :rejected_publish] => :build_published
    end

    event :fail_publish do
      transition [:build_publish, :rejected_publish] => :failed_publish
    end

    event :publish do
      transition [
        :success,
        :failed_publish,
        :build_published,
        :tests_failed,
        :failed_publish_into_testing,
        :build_published_into_testing
      ] => :build_publish
      transition [:success, :failed_publish, :failed_publish_into_testing] => :failed_publish
    end

    event :reject_publish do
      transition [
        :success,
        :failed_publish,
        :tests_failed,
        :failed_publish_into_testing,
        :build_published_into_testing
      ] => :rejected_publish
    end

    # ===== into testing - start

    event :published_into_testing do
      transition [:build_publish_into_testing, :rejected_publish] => :build_published_into_testing
    end

    event :fail_publish_into_testing do
      transition [:build_publish_into_testing, :rejected_publish] => :failed_publish_into_testing
    end

    event :publish_into_testing do
      transition [
        :success,
        :failed_publish,
        :tests_failed,
        :failed_publish_into_testing,
        :build_published_into_testing
      ] => :build_publish_into_testing
      transition [:success, :failed_publish, :failed_publish_into_testing] => :failed_publish_into_testing
    end

    # ===== into testing - end

    event :build_success do
      transition [:build_started, :build_canceled] => :success
    end

    [:build_error, :tests_failed].each do |kind|
      event kind do
        transition [:build_started, :build_canceling] => kind
      end
    end

    HUMAN_STATUSES.each do |code,name|
      state name, value: code
    end
  end

  later :publish, queue: :clone_build
  later :add_job_to_abf_worker_queue, queue: :clone_build

  HUMAN_CONTAINER_STATUSES = { WAITING_FOR_RESPONSE => :waiting_for_publish,
                               BUILD_PUBLISHED => :container_published,
                               BUILD_PUBLISH => :container_publish,
                               FAILED_PUBLISH => :container_failed_publish
                              }.freeze

  state_machine :container_status, initial: :waiting_for_publish do

    after_transition on: :publish_container, do: :create_container
    after_transition on: [:fail_publish_container, :destroy_container],
      do: :remove_container

    event :publish_container do
      transition [:waiting_for_publish, :container_failed_publish] => :container_publish,
        if: :can_create_container?
    end

    event :published_container do
      transition container_publish: :container_published
    end

    event :fail_publish_container do
      transition container_publish: :container_failed_publish
    end

    event :destroy_container do
      transition [:container_failed_publish, :container_published, :waiting_for_publish] => :waiting_for_publish
    end

    HUMAN_CONTAINER_STATUSES.each do |code,name|
      state name, value: code
    end
  end

  def set_version_and_tag
    pkg = self.packages.where(package_type: 'source', project_id: self.project_id).first
    # TODO: remove 'return' after deployment ABF kernel 2.0
    return if pkg.nil? # For old client that does not sends data about packages
    self.package_version = "#{pkg.platform.name}-#{pkg.version}-#{pkg.release}"
    system("cd #{self.project.repo.path} && git tag #{self.package_version} #{self.commit_hash}") # TODO REDO through grit
    save
  end

  def actualize_packages
    ActiveRecord::Base.transaction do
      # packages from previous build_list
      self.last_published.limit(2).last.packages.update_all actual: false
      self.packages.update_all actual: true
    end
  end

  def can_create_container?
    [SUCCESS, BUILD_PUBLISH, FAILED_PUBLISH, BUILD_PUBLISHED, TESTS_FAILED, BUILD_PUBLISHED_INTO_TESTING, FAILED_PUBLISH_INTO_TESTING].include?(status) && [WAITING_FOR_RESPONSE, FAILED_PUBLISH].include?(container_status)
  end

  def can_publish_into_repository?
    return true if !save_to_repository.synchronizing_publications? || save_to_platform.personal? || project.architecture_dependent?
    arch_ids = save_to_platform.platform_arch_settings.by_default.pluck(:arch_id)
    BuildList.where(
      project_id: project_id,
      save_to_repository_id: save_to_repository_id,
      arch_id: arch_ids,
      commit_hash: commit_hash,
      status: [
        SUCCESS,
        BUILD_PUBLISHED,
        BUILD_PUBLISH,
        FAILED_PUBLISH,
        TESTS_FAILED,
        BUILD_PUBLISHED_INTO_TESTING,
        BUILD_PUBLISH_INTO_TESTING,
        FAILED_PUBLISH_INTO_TESTING
      ]
    ).group(:arch_id).count == arch_ids.size
  end

  #TODO: Share this checking on product owner.
  def can_cancel?
    build_started? || build_pending?
  end

  # Comparison between versions of current and last published build_list
  # @return [Boolean]
  # - false if no new packages
  # - false if version of packages is less than version of pubished packages.
  # - true if version of packages is equal to version of pubished packages (only if platform is not released).
  # - true if version of packages is greater than version of pubished packages.
  def has_new_packages?
    if last_bl = last_published.joins(:source_packages).where(build_list_packages: {actual: true}).last
      source_packages.each do |nsp|
        sp = last_bl.source_packages.find{ |sp| nsp.name == sp.name }
        return true unless sp
        comparison = nsp.rpmvercmp(sp)
        return comparison == 1 || (comparison == 0 && !save_to_platform.released?)
      end
    else
      return true # no published packages
    end
    return false # no new packages
  end

  def auto_publish?
    auto_publish_status == AUTO_PUBLISH_STATUS_DEFAULT
  end

  def auto_publish_into_testing?
    auto_publish_status == AUTO_PUBLISH_STATUS_TESTING
  end

  # TODO: remove later
  def auto_publish=(value)
    self.auto_publish_status = value.present? ? AUTO_PUBLISH_STATUS_DEFAULT : AUTO_PUBLISH_STATUS_NONE
  end

  def can_auto_publish?
    auto_publish? && can_publish? && has_new_packages? && can_publish_into_repository?
  end

  def can_publish?
    [SUCCESS, FAILED_PUBLISH, BUILD_PUBLISHED, TESTS_FAILED, BUILD_PUBLISHED_INTO_TESTING, FAILED_PUBLISH_INTO_TESTING].include?(status) && extra_build_lists_published? && save_to_repository.projects.exists?(id: project_id)
  end

  def extra_build_lists_published?
    # All extra build lists should be published before publishing this build list for main platforms!
    return true unless save_to_platform.main?
    BuildList.where(id: extra_build_lists).where('status != ?', BUILD_PUBLISHED).count == 0
  end

  def human_average_build_time
    I18n.t('layout.project_statistics.human_average_build_time', {hours: (average_build_time/3600).to_i, minutes: (average_build_time%3600/60).to_i})
  end

  def formatted_average_build_time
    "%02d:%02d" % [average_build_time / 3600, average_build_time % 3600 / 60]
  end

  def average_build_time
    return 0 unless project
    @average_build_time ||= project.project_statistics.
      find{ |ps| ps.arch_id == arch_id }.try(:average_build_time) || 0
  end

  def self.human_status(status)
    I18n.t("layout.build_lists.statuses.#{HUMAN_STATUSES[status]}")
  end

  def human_status
    self.class.human_status(status)
  end

  def self.status_by_human(human)
    HUMAN_STATUSES.key human
  end

  def set_items(items_hash)
    self.items = []

    items_hash.each do |level, items|
      items.each do |item|
        self.items << self.items.build(name: item['name'], version: item['version'], level: level.to_i)
      end
    end
  end

  def set_packages(pkg_hash, project_name)
    prj = Project.joins(repositories: :platform).where('platforms.id = ?', save_to_platform.id).find_by_name!(project_name)
    build_package(pkg_hash['srpm'], 'source', prj) {|p| p.save!}
    pkg_hash['rpm'].each do |rpm_hash|
      build_package(rpm_hash, 'binary', prj) {|p| p.save!}
    end
  end

  def event_log_message
    {project: project.name, version: project_version, arch: arch.name}.inspect
  end

  def current_duration
    (Time.now.utc - started_at.utc).to_i
  end

  def human_current_duration
    I18n.t("layout.build_lists.human_current_duration", {hours: (current_duration/3600).to_i, minutes: (current_duration%3600/60).to_i})
  end

  def human_duration
    I18n.t("layout.build_lists.human_duration", {hours: (duration.to_i/3600).to_i, minutes: (duration.to_i%3600/60).to_i})
  end

  def in_work?
    status == BUILD_STARTED
    #[WAITING_FOR_RESPONSE, BUILD_PENDING, BUILD_STARTED].include?(status)
  end

  def associate_and_create_advisory(params)
    build_advisory(params){ |a| a.update_type = update_type }
    advisory.attach_build_list(self)
  end

  def can_attach_to_advisory?
    !save_to_repository.publish_without_qa &&
      save_to_platform.main? &&
      save_to_platform.released &&
      build_published?
  end

  def log(load_lines)
    new_core? ? abf_worker_log : I18n.t('layout.build_lists.log.not_available')
  end

  def last_published(testing = false)
    BuildList.where(project_id: self.project_id,
                    save_to_repository_id: self.save_to_repository_id)
             .for_platform(self.build_for_platform_id)
             .scoped_to_arch(self.arch_id)
             .for_status(testing ? BUILD_PUBLISHED_INTO_TESTING : BUILD_PUBLISHED)
             .recent
  end

  def sha1_of_file_store_files
    packages.pluck(:sha1).compact | (results || []).map{ |r| r['sha1'] }.compact
  end

  def abf_worker_args
    repos = include_repos
    include_repos_hash = {}.tap do |h|
      Repository.where(id: (repos | (extra_repositories || [])) ).each do |repo|
        path, prefix = repo.platform.public_downloads_url(
          repo.platform.main? ? nil : build_for_platform.name,
          arch.name,
          repo.name
        ), "#{repo.platform.name}_#{repo.name}_"
        h["#{prefix}release"] = insert_token_to_path(path + 'release', repo.platform)
        h["#{prefix}updates"] = insert_token_to_path(path + 'updates', repo.platform) if repo.platform.main?
        h["#{prefix}testing"] = insert_token_to_path(path + 'testing', repo.platform) if include_testing_subrepository?
      end
    end
    host = EventLog.current_controller.request.host_with_port rescue ::Rosa::Application.config.action_mailer.default_url_options[:host]
    BuildList.where(id: extra_build_lists).each do |bl|
      path  = "#{APP_CONFIG['downloads_url']}/#{bl.save_to_platform.name}/container/"
      path << "#{bl.id}/#{bl.arch.name}/#{bl.save_to_repository.name}/release"
      include_repos_hash["container_#{bl.id}"] = insert_token_to_path(path, bl.save_to_platform)
    end

    git_project_address = project.git_project_address user
    # git_project_address.gsub!(/^http:\/\/(0\.0\.0\.0|localhost)\:[\d]+/, 'https://abf.rosalinux.ru') unless Rails.env.production?

    cmd_params = {
      'GIT_PROJECT_ADDRESS'           => git_project_address,
      'COMMIT_HASH'                   => commit_hash,
      'EXTRA_CFG_OPTIONS'             => extra_params['cfg_options'],
      'EXTRA_CFG_URPM_OPTIONS'        => extra_params['cfg_urpm_options'],
      'EXTRA_BUILD_SRC_RPM_OPTIONS'   => extra_params['build_src_rpm'],
      'EXTRA_BUILD_RPM_OPTIONS'       => extra_params['build_rpm']
    }.map{ |k, v| "#{k}='#{v}'" }.join(' ')

    {
      id:            id,
      time_living:   (build_for_platform.platform_arch_settings.by_arch(arch).first.try(:time_living) || PlatformArchSetting::DEFAULT_TIME_LIVING),
      distrib_type:  build_for_platform.distrib_type,
      cmd_params:    cmd_params,
      include_repos: include_repos_hash,
      platform:      {
                       type: build_for_platform.distrib_type,
                       name: build_for_platform.name,
                       arch: arch.name
      },
      user:          {uname: user.uname, email: user.email}
    }
  end

  def cleanup_packages_from_testing
    AbfWorker::BuildListsPublishTaskManager.cleanup_packages_from_testing(
      build_for_platform_id,
      save_to_repository_id,
      id
    )
  end

  def delayed_add_job_to_abf_worker_queue(*args)
    restart_job if status == BUILD_PENDING
  end
  later :delayed_add_job_to_abf_worker_queue, delay: 60, queue: :clone_build

  protected

  def create_container
    AbfWorker::BuildListsPublishTaskManager.create_container_for self
  end

  def remove_container
    system "rm -rf #{save_to_platform.path}/container/#{id}" if save_to_platform
  end

  def abf_worker_priority
    mass_build_id ? '' : 'default'
  end

  def abf_worker_base_queue
    'rpm_worker'
  end

  def insert_token_to_path(path, platform)
    if platform.hidden?
      path.gsub(/^http:\/\//, "http://#{user.authentication_token}:@")
    else
      path
    end
  end

  def notify_users
    unless mass_build_id
      users = [user, publisher].compact.uniq.select{ |u| u.notifier.can_notify? && u.notifier.new_build? }

      # find associated users
      users |= project.all_members.select do |u|
        u.notifier.can_notify? && u.notifier.new_associated_build?
      end if project
      users.each{ |u| UserMailer.build_list_notification(self, u).deliver }
    end
  end # notify_users

  def build_package(pkg_hash, package_type, prj)
    packages.create(pkg_hash) do |p|
      p.project = prj
      p.platform = save_to_platform
      p.package_type = package_type
      yield p
    end
  end

  def set_publisher
    self.publisher ||= user
    save
  end

  def current_ability
    @current_ability ||= Ability.new(user)
  end

  def prepare_extra_repositories
    if save_to_platform && save_to_platform.main?
      self.extra_repositories = nil
    else
      self.extra_repositories = Repository.joins(:platform).
        where(id: extra_repositories, platforms: {platform_type: 'personal'}).
        accessible_by(current_ability, :read).pluck('repositories.id')
    end
  end

  def prepare_extra_build_lists
    bls = BuildList.for_extra_build_lists(extra_build_lists, current_ability, save_to_platform)
    if save_to_platform
      if save_to_platform.distrib_type == 'rhel'
        bls = bls.where('
          (build_lists.arch_id = ? AND projects.publish_i686_into_x86_64 is not true) OR
          (projects.publish_i686_into_x86_64 is true)
        ', arch_id).joins(:project)
      else
        bls = bls.where(arch_id: arch_id)
      end
    end
    self.extra_build_lists = bls.pluck('build_lists.id')
  end

  def prepare_auto_publish_status
    if external_nodes.present?
      self.auto_publish_status = AUTO_PUBLISH_STATUS_NONE
    end
    if auto_publish? && !save_to_repository.publish_without_qa?
      self.auto_publish_status = AUTO_PUBLISH_STATUS_NONE
    end
    if auto_publish? || auto_publish_into_testing?
      self.auto_create_container = false
    end
  end

  def prepare_extra_params
    if extra_params.present?
      params = extra_params.slice(*BuildList::EXTRA_PARAMS)
      params.update(params) do |k,v|
        v.strip.gsub(I18n.t("activerecord.attributes.build_list.extra_params.#{k}"), '').gsub(/[^\w\s-]/, '')
      end
      self.extra_params = params.select{ |k,v| v.present? }
    end
  end
end
