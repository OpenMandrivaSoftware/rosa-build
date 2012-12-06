# -*- encoding : utf-8 -*-
class ProductBuildList < ActiveRecord::Base
  include Modules::Models::CommitAndVersion
  include AbfWorker::ModelHelper
  delegate :url_helpers, to: 'Rails.application.routes'

  BUILD_COMPLETED = 0
  BUILD_FAILED    = 1
  BUILD_PENDING   = 2
  BUILD_STARTED   = 3
  BUILD_CANCELED  = 4
  BUILD_CANCELING = 5

  STATUSES = [  BUILD_STARTED,
                BUILD_COMPLETED,
                BUILD_FAILED,
                BUILD_PENDING,
                BUILD_CANCELED,
                BUILD_CANCELING
              ]

  HUMAN_STATUSES = { BUILD_STARTED => :build_started,
                     BUILD_COMPLETED => :build_completed,
                     BUILD_FAILED => :build_failed,
                     BUILD_PENDING => :build_pending,
                     BUILD_CANCELED => :build_canceled,
                     BUILD_CANCELING => :build_canceling
                    }

  belongs_to :product
  belongs_to :project
  belongs_to :arch


  validates :product_id,
            :status,
            :project_id,
            :main_script,
            :time_living,
            :arch_id, :presence => true
  validates :status, :inclusion => { :in => STATUSES }

  attr_accessor :base_url
  attr_accessible :status,
                  :base_url,
                  :branch,
                  :project_id,
                  :main_script,
                  :params,
                  :project_version,
                  :commit_hash,
                  :time_living,
                  :arch_id
  attr_readonly :product_id
  serialize :results, Array


  scope :default_order, order('updated_at DESC')
  scope :for_status, lambda {|status| where(:status => status) }
  scope :for_user, lambda { |user| where(:user_id => user.id)  }
  scope :scoped_to_product_name, lambda {|product_name| joins(:product).where('products.name LIKE ?', "%#{product_name}%")}
  scope :recent, order("#{table_name}.updated_at DESC")

  after_create :add_job_to_abf_worker_queue
  before_destroy :can_destroy?
  after_destroy :xml_delete_iso_container

  def build_started?
    status == BUILD_STARTED
  end

  def build_canceling?
    status == BUILD_CANCELING
  end

  def can_cancel?
    [BUILD_STARTED, BUILD_PENDING].include? status
  end

  def container_path
    "/downloads/#{product.platform.name}/product/#{id}/"
  end

  def event_log_message
    {:product => product.name}.inspect
  end

  def self.human_status(status)
    I18n.t("layout.product_build_lists.statuses.#{HUMAN_STATUSES[status]}")
  end

  def human_status
    self.class.human_status(status)
  end

  def can_destroy?
    [BUILD_COMPLETED, BUILD_FAILED, BUILD_CANCELED].include? status
  end

  protected

  def abf_worker_args
    file_name = "#{project.owner.uname}-#{project.name}-#{commit_hash}"
    srcpath = url_helpers.archive_url(
      project.owner,
      project.name,
      file_name,
      'tar.gz',
      :host => ActionMailer::Base.default_url_options[:host]
    )
    {
      :id => id,
      # TODO: remove comment
      # :srcpath => 'http://dl.dropbox.com/u/945501/avokhmin-test-iso-script-5d9b463d4e9c06ea8e7c89e1b7ff5cb37e99e27f.tar.gz',
      :srcpath => srcpath,
      :params => params,
      :time_living => time_living,
      :main_script => main_script,
      :arch => arch.name,
      :distrib_type => product.platform.distrib_type
    }
  end

  def xml_delete_iso_container
    # TODO: write new worker for delete
    if project
      raise "Failed to destroy product_build_list #{id} inside platform #{product.platform.name} (Not Implemented)."
    else
      result = ProductBuilder.delete_iso_container self
      if result == ProductBuilder::SUCCESS
        return true
      else
        raise "Failed to destroy product_build_list #{id} inside platform #{product.platform.name} with code #{result}."
      end
    end
  end
end
