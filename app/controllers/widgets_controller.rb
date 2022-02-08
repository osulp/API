class WidgetsController < ApplicationController
  include ActionController::MimeResponds
  before_action :set_params

  def hours
    @limited = false
    hours_layout

    respond_to do |format|
      format.html { render html: html_content }
      format.js   { render js: js_constructor }
    end
  end

  def hours_limited
    @limited = true
    hours_layout

    respond_to do |format|
      format.html { render html: html_content }
      format.js   { render js: js_constructor }
    end
  end

  def hours_layout
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
  end

  private

  def js_constructor
    content = ActionController::Base.new.render_to_string("widgets/hours/#{params[:template]}",
                                                          layout: false,
                                                          :locals => {
                                                              :hours => JSON.parse(@hours),
                                                              :limited => @limited
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
                    limited: @limited)
    alma.hours_json
  end

  def weekly_dates
    [Time.zone.today.strftime("%Y-%m-%d"), (Time.zone.today.beginning_of_week(:sunday)+6.days).strftime("%Y-%m-%d")]
  end

  def alma_todays_hours_request
    alma = Alma.new(date_from: todays_dates.first,
                    date_to: todays_dates.last,
                    limited: @limited)
    alma.hours_json
  end

  def todays_dates
    [Time.zone.today.strftime("%Y-%m-%d"), Time.zone.today.strftime("%Y-%m-%d")]
  end

  def alma_special_hours_request
    alma = AlmaSpecialHours.new
    API::SpecialHoursXmlToJsonParser.call(alma.xml_document)
  end

  def set_params
    @template = params[:template]
  end
end
