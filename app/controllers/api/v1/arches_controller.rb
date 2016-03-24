class Api::V1::ArchesController < Api::V1::BaseController
  skip_before_action :check_auth if APP_CONFIG['anonymous_access']
  before_action :authenticate_user! unless APP_CONFIG['anonymous_access']

  def index
    authorize :arch
    @arches = Arch.order(:id).paginate(paginate_params)
  end

end
