require 'nokogiri'
require 'open-uri'

module Project::MassCreate
  extend ActiveSupport::Concern
  
  module ClassMethods
    def run_mass_create(url, visibility, owner, add_to_repository_id)
      repository = Repository.find add_to_repository_id
      open(url) { |f|
        f.each_line {
            |line|
            project = owner.projects.build(
              name: line,
              visibility:  visibility,
              is_package: false
            )
            project.owner = owner
            if project.save
              repository.projects << project rescue nil
              project.update_attributes(is_package: true)
            end
          }
        }
    end
  end
end