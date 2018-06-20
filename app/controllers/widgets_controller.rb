class WidgetsController < ApplicationController
  include ActionController::MimeResponds

  def show
    dates = [Date.today, Date.today + 6.days]
    alma = Alma.new(dates.first, dates.last)
    @hours = API::HoursXmlToJsonParser.call(alma.xml_document)

    respond_to do |format|
      format.js   { render js: js_constructor }
    end
  end

  private

  def js_constructor
    content = ActionController::Base.new.render_to_string("widgets/#{params[:template]}",
                                                          layout: false,
                                                          :locals => {
                                                              :hours => JSON.parse(@hours)
                                                          })
    "document.write(#{content.to_json})"
  end
end