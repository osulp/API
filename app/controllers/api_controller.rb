class ApiController < ApplicationController
  before_action :set_params

  def hours
    dates = @dates.blank? ? [Time.zone.today.strftime('%Y-%m-%d'), Time.zone.today.strftime('%Y-%m-%d')] : @dates.sort
    alma = Alma.new(date_from: dates.first, date_to: dates.last, limited: false)
    @hours = alma.hours_json

    render json: @hours
  end

  def hours_limited
    dates = @dates.blank? ? [Time.zone.today.strftime('%Y-%m-%d'), Time.zone.today.strftime('%Y-%m-%d')] : @dates.sort
    alma = Alma.new(date_from: dates.first, date_to: dates.last, limited: true)
    @hours = alma.hours_json

    render json: @hours
  end

  def special_hours
    alma_special_hours = AlmaSpecialHours.new
    @special_hours = API::SpecialHoursXmlToJsonParser.call(alma_special_hours.xml_document)

    render json: @special_hours
  end

  private

  def set_params
    # expecting a JSON array of dates, see following example:
    # {"dates":["2016-01-01","2016-01-02","2016-01-03"]}
    @dates = params[:dates]
  end
end
