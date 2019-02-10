module AbfWorker
  class BaseObserver < BaseActiveRecordJob
    include Sidekiq::Worker

    COMPLETED     = 0
    FAILED        = 1
    PENDING       = 2
    STARTED       = 3
    CANCELED      = 4
    TESTS_FAILED  = 5

    attr_accessor :status, :options

    def perform_with_ar_connection(options)
      @status         = options['status'].to_i
      @options        = options
      real_perform
    end

    def real_perform
      raise NotImplementedError, "You should implement this method"
    end

    protected

    def subject
      @subject ||= @subject_class.find(options['id']) rescue nil
    end

    def update_results
      now     = Time.zone.now.to_i
      results = options['results'] || []
      results.each{ |r| r['timestamp'] = now }
      results += subject.results || []
      sort_results_and_save(results)
    end

    def sort_results_and_save(results, item = subject)
      item.results = results.sort_by{ |r| [r['timestamp'].to_s, r['file_name'].to_s] }
      item.save(validate: false)
    end

  end
end