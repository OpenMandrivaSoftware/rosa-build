require 'csv'
class Api::V1::RepositoryPackagePresenter
  CSV_HEADERS = {
    project_owner: 'Project owner',
    project_name: 'Project name',
    package_name: 'Package name',
    epoch: 'Epoch',
    version: 'Version',
    release: 'Release',
    maintainer_uname: 'Maintainer uname',
    maintainer_email: 'Maintainer email'
  }

  attr_reader :package
  delegate *%i(project name epoch version release assignee build_list), to: :package

  def initialize(package)
    @package = package
  end

  def to_csv_row
    CSV::Row.new(
      CSV_HEADERS.keys,
      [
        project.owner_uname,
        project.name,
        name,
        epoch,
        version,
        release,
        assignee.uname,
        assignee.email
      ]
    )
  end

  def self.csv_header
    # Using ruby's built-in CSV::Row class
    # true - means its a header
    CSV::Row.new CSV_HEADERS.keys, CSV_HEADERS.values, true
  end

end
