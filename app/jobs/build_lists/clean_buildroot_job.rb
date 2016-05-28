module BuildLists
  class CleanBuildrootJob < BaseActiveRecordJob
    include Sidekiq::Worker
    sidekiq_options :queue => :middle

    FILENAME = 'rpm-buildroot.tar.gz'

    def perform_with_ar_connection
      build_lists = BuildList.where(save_buildroot: true).
        for_status(BuildList::BUILD_ERROR).
        where('updated_at < ?', Time.now - 1.hour).
        where('results ~ ?', "file_name: #{FILENAME}")

      build_lists.find_each do |build_list|
        buildroots = build_list.results.select do |r|
          r['file_name'] == FILENAME
        end
        build_list.results -= buildroots
        build_list.save(validate: false)

        clean_file_store buildroots
      end
    end

    private

    def clean_file_store(buildroots)
      buildroots.each do |r|
        FileStoreService::File.new(sha1: r['sha1']).destroy
      end
    end

  end
end