class WidgetsController < ApplicationController
  include ActionController::MimeResponds
  before_action :set_params

  def hours
    @layout = 'basic_widget'
    if @template == 'calendar'
      @hours = '{}'
      @layout = 'calendar_widget'
    elsif @template == 'special_hours'
      @hours = alma_special_hours_request
    elsif @template == 'todays_hours'
      @hours = alma_todays_hours_request
    else
      @hours = alma_request
    end

    respond_to do |format|
      format.html { render html: html_content }
      format.js   { render js: js_constructor }
    end
  end

  private

  def js_constructor
    content = ActionController::Base.new.render_to_string("widgets/hours/#{params[:template]}",
                                                          layout: false,
                                                          :locals => {
                                                              :hours => JSON.parse(@hours)
                                                          })
    "document.write(#{content.to_json})"
  end

  def html_content
    ActionController::Base.new.render_to_string("widgets/hours/#{params[:template]}",
                                                layout: @layout,
                                                :locals => {
                                                    :hours => JSON.parse(@hours)
                                                })
  end

  def alma_request
    dates = [Date.today.strftime("%Y-%m-%d"), (Date.today+6.days).strftime("%Y-%m-%d")]
    alma = Alma.new(dates.first, dates.last)
    API::HoursXmlToJsonParser.call(alma.xml_document, dates)
  end

  def alma_todays_hours_request
    dates = [Date.today.strftime("%Y-%m-%d"), Date.today.strftime("%Y-%m-%d")]
    alma = Alma.new(dates.first, dates.last)
    API::HoursXmlToJsonParser.call(alma.xml_document, dates)
  end

  def alma_special_hours_request
    alma = AlmaSpecialHours.new
    API::SpecialHoursXmlToJsonParser.call(alma.xml_document)
  end

  def set_params
    @template = params[:template]
  end
end