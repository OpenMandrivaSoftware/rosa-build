module AbfWorker
  class RpmWorkerObserver < AbfWorker::BaseObserver
    RESTARTED_BUILD_LISTS = 'abf-worker::rpm-worker-observer::restarted-build-lists'

    # EXIT CODES:
    # 6 - Unpermitted architecture
    # other - Build error
    EXIT_CODE_UNPERMITTED_ARCHITECTURE = 6

    sidekiq_options :queue => :rpm_worker_observer

    def real_perform
      @subject_class = BuildList
      return if !subject
      unless subject.valid? && restart_task
        if options['feedback_from_user']
          user = User.find options['feedback_from_user']
          return if !user.system? && subject.builder != user
        end

        fill_container_data if status != STARTED

        unless subject.valid?
          subject.build_error(false)
          subject.save(validate: false)
          return
        end

        if options['hostname']
          subject.update_attribute(:hostname, options['hostname'])
        end

        if options['fail_reason']
          subject.update_attribute(:fail_reason, options['fail_reason'])
        end

        if options['commit_hash']
          subject.update_attribute(:commit_hash, options['commit_hash'])
        end

        rerunning_tests = subject.rerunning_tests?

        case status
        when COMPLETED
          subject.build_success
          if subject.can_auto_publish? && subject.can_publish?
            subject.publish
          elsif subject.auto_publish_into_testing? && subject.can_publish_into_testing?
            subject.publish_into_testing
          end
        when FAILED

          case options['exit_status'].to_i
          when EXIT_CODE_UNPERMITTED_ARCHITECTURE
            subject.unpermitted_arch
          else
            subject.build_error
          end

        when STARTED
          subject.start_build
        when CANCELED
          subject.build_canceled
        when TESTS_FAILED
          subject.tests_failed
        end

        if !rerunning_tests && [TESTS_FAILED, COMPLETED].include?(status)
          subject.publish_container if subject.auto_create_container?
        end
      end
    end

    protected

    def restart_task
      return false if status != FAILED
      if Redis.current.lrem(RESTARTED_BUILD_LISTS, 0, subject.id) > 0 || (options['results'] || []).size > 1
        return false
      else
        Redis.current.lpush RESTARTED_BUILD_LISTS, subject.id
        subject.update_column(:status, BuildList::BUILD_PENDING)
        return true
      end
    end

    def fill_container_data
      (options['packages'] || []).each do |package|
        package = subject.packages.build(package)
        package.package_type  = package['fullname'] =~ /.*\.src\.rpm$/ ? 'source' : 'binary'
        package.project_id    = subject.project_id
        package.platform_id   = subject.save_to_platform_id
        package.save!
      end
      update_results
    end

  end
end