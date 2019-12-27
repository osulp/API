class WidgetsController < ApplicationController
  include ActionController::MimeResponds
  before_action :set_params

  def hours
    @layout = 'basic_widget'
    if @template == 'calendar'
      @hours = '{}'
      @layout = 'calendar_widget'
    elsif @template == 'special_hours'
      @hours = alma_special_hours_request || '{}'
    elsif @template == 'todays_hours'
      @hours = alma_todays_hours_request || '{}'
    else
      @hours = alma_request || '{}'
    end

    respond_to do |format|
      format.html { render html: html_content }
      format.js   { render js: js_constructor }
    end
  end

  def hours_limited
    @layout = 'basic_widget'
    @limited = true
    if @template == 'calendar'
      @hours = '{}'
      @layout = 'calendar_widget'
    elsif @template == 'special_hours'
      @hours = alma_special_hours_request || '{}'
    elsif @template == 'todays_hours'
      @hours = alma_todays_hours_request_limited || '{}'
    else
      @hours = alma_request_limited || '{}'
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
                                                    :hours => JSON.parse(@hours),
                                                    :limited => @limited
                                                })
  end

  def alma_request
    alma = Alma.new(date_from: weekly_dates.first,
                    date_to: weekly_dates.last,
                    limited: false)
    alma.hours_json
  end

  def alma_request_limited
    alma = Alma.new(date_from: weekly_dates.first,
                    date_to: weekly_dates.last,
                    limited: true)
    alma.hours_json
  end

  def weekly_dates
    [Time.zone.today.strftime('%Y-%m-%d'), (Time.zone.today+6.days).strftime('%Y-%m-%d')]
  end

  def alma_todays_hours_request
    alma = Alma.new(date_from: todays_dates.first,
                    date_to: todays_dates.last,
                    limited: false)
    alma.hours_json
  end

  def alma_todays_hours_request_limited
    alma = Alma.new(date_from: todays_dates.first,
                    date_to: todays_dates.last,
                    limited: true)
    alma.hours_json
  end

  def todays_dates
    [Time.zone.today.strftime('%Y-%m-%d'), Time.zone.today.strftime('%Y-%m-%d')]
  end

  def alma_special_hours_request
    alma = AlmaSpecialHours.new
    API::SpecialHoursXmlToJsonParser.call(alma.xml_document)
  end

  def set_params
    @template = params[:template]
  end
end
