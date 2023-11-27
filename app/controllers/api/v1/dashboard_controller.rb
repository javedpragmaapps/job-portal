class Api::V1::DashboardController < ApplicationController
  def index
    render json: {error: "Job Not Found."}
  end


  # dafault funcation to render content
  ## this way we can add multiple render funcation on the comtroller otherwise DoubleRenderError was triggered
  def render_json(data, status_code, main_key = 'data')
    render json: { "#{main_key}": data }, status: status_code
  end
end
