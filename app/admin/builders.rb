ActiveAdmin.register_page 'Builders' do
  content do
    table do
      thead do
        ["id", "system?", "Hostname", "Busy workers", "Query String"].each &method(:th)
      end
      tbody do
        RpmBuildNode.all.to_a.each do |node|
          next unless node.user_id
          tr do
            %w(id system host busy_workers query_string).each do |col|
              td { node.send(col) }
            end
          end
        end
      end
    end
  end
end
