require 'nokogiri'
require 'open-uri'

module Project::MassCreate
  extend ActiveSupport::Concern
  
  module ClassMethods
    def run_mass_create(url, visibility, owner, add_to_repository_id)
      repository = Repository.find add_to_repository_id
      open(url) do |f|
        projects = []
        ActiveRecord::Base.transaction do
          f.each_line do |line|
            project = owner.projects.build(
              name: line,
              visibility:  visibility,
              is_package: false
            )
            project.owner = owner
            projects << project if project.save
          end
        end
        ActiveRecord::Base.transaction do
          projects.each do |item|
            repository.projects << item
            item.update_attributes(is_package: true)
          end
        end
      end
    end
  end
end