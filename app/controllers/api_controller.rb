class ApiController < ApplicationController
  before_action :set_params

  def hours
    dates = @dates.blank? ?  [Date.today.strftime("%Y-%m-%d"), Date.today.strftime("%Y-%m-%d")] : @dates.sort
    alma = Alma.new(dates.first, dates.last)
    @hours = API::HoursXmlToJsonParser.call(alma.xml_document)

    render json: @hours
  end

  def special_hours
    alma_special_hours = AlmaSpecialHours.new
    @special_hours = API::SpecialHoursXmlToJsonParser.call(alma_special_hours.xml_document)

    # @special_hours = alma_special_hours.xml_document
    render json: @special_hours
  end

  private

  def set_params
    # expecting a JSON array of dates, see following example:
    # {"dates":["2016-01-01","2016-01-02","2016-01-03"]}
    @dates = params[:dates]
  end
end
