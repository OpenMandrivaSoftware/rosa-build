require 'sidekiq/scheduler'

Kiqit.config.enabled = true

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq.schedule = YAML
      .load_file(File.expand_path('../../../config/schedule.yml', __FILE__))
    Sidekiq::Scheduler.reload_schedule!
  end
end

if ENV["PROFILE"]
  require "objspace"
  ObjectSpace.trace_object_allocations_start
  Sidekiq.logger.info "allocations tracing enabled"

  # module Sidekiq
  #   module Middleware
  #     module Server
  #       class Profiler
  #         # Number of jobs to process before reporting
  #         JOBS = 100

  #         class << self
  #           mattr_accessor :counter
  #           self.counter = 0

  #           def synchronize(&block)
  #             @lock ||= Mutex.new
  #             @lock.synchronize(&block)
  #           end
  #         end

  #         def call(worker_instance, item, queue)
  #           begin
  #             yield
  #           ensure
  #             self.class.synchronize do
  #               self.class.counter += 1

  #               if self.class.counter % JOBS == 0
  #                 Sidekiq.logger.info "reporting allocations after #{self.class.counter} jobs"
  #                 GC.start
  #                 out = File.open("/tmp/heap.json", "w")
  #                 ObjectSpace.dump_all(output: out)
  #                 out.close
  #                 Sidekiq.logger.info "heap saved to heap.json"
  #               end
  #             end
  #           end
  #         end
  #       end
  #     end
  #   end
  # end

  # Sidekiq.configure_server do |config|
  #   config.server_middleware do |chain|
  #     chain.add Sidekiq::Middleware::Server::Profiler
  #   end
  # end
end