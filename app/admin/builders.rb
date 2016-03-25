ActiveAdmin.register_page 'Builders' do
  content do
    table do
      thead do
        ["id", "system?", "Hostname", "Busy workers", "Supported Arches", "Supported Platforms"].each &method(:th)
      end
      tbody do
        RpmBuildNode.all.to_a.each do |node|
          next unless node.user_id
          tr do
            %w(id system host busy_workers supported_arches supported_platforms).each do |col|
              td { node.send(col) }
            end
          end
        end
      end
    end
  end
end
