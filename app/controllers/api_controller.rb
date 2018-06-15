class ApiController < ApplicationController
  before_action :set_params, only: [:hours]

  def hours
    dates = @dates.nil? ? Date.today : @dates

    alma = Alma.new(day, day)
    hours = Api::HoursXmlToJsonParser.call(alma.xml_document)

    render json: hours
  end

  def set_params
    @dates = params[:dates]
  end

end