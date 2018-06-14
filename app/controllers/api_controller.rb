class ApiController < ApplicationController
  def hours
    day = params[:day].nil? : Date.today : params[:day]
    response_from_api = "" #Call API here to fetch hours with day
    json = "" #HoursXmlToJsonParser.call(reponse_from_api)
    respond_to do |format|
      format.json { render json: json }
    end
  end

  def multi_day_hours
    beginning_day = params[:beginning_day].nil? : Date.today : params[:beginning_day] 
    ending_day = params[:ending_day].nil? : Date.today : params[:ending_day] 
    response_from_api = "" #Call API here to fetch hours with beginning_day and ending_day
    json = "" #HoursXmlToJsonParser.call(reponse_from_api)
    respond_to do |format|
      format.json { render json: json }
    end
  end
end