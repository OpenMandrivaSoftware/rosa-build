class BaseActiveRecordJob
  def perform(*args)
    ActiveRecord::Base.connection_pool.with_connection do
      perform_with_ar_connection(*args)
    end
  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end
end