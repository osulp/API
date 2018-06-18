class ApiController < ApplicationController
  before_action :set_params

  def hours
    dates = @dates.blank? ? [Date.today, Date.today] : @dates.sort
    alma = Alma.new(dates.first, dates.last)
    hours = API::HoursXmlToJsonParser.call(alma.xml_document)

    render json: hours
  end

  private

  def set_params
    # expecting a JSON array of dates, see following example:
    # {"dates":["2016-01-01","2016-01-02","2016-01-03"]}
    @dates = params[:dates]
  end

end