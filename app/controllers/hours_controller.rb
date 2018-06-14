class HoursController < ApplicationController
  before_action :set_params, only: [:index, :show]

  # GET /hours
  def index
    # @hours = []
    # json_response(@hours)
    alma = Alma.new(@date_from, @date_to)
    render json: alma.open_hours
  end

  # GET /hours/:id
  # def show
  #   json_response(@hour)
  # end

  private

  def set_params
    @date_from = params[:date_from]
    @date_to = params[:date_to]
  end
end
