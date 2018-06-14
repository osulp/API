class AlmaOpenHoursDay
  attr_reader :date, :day_of_week, :hours

  ##
  # Initialize an alma_open_hours_day object
  # @param [Nokogiri::XML::Node] node - the xml node with this obj
  def initialize(node)
    @date = Time.zone.parse(node.at_xpath('date').text)
    @day_of_week = node.at_xpath('day_of_week').attr('desc')
    @hours = node.at_xpath('hours').to_s
    # TODO: parse and format hours, i.e. using HoursXmlToJsonParser when ready
    # @hours = HoursXmlToJsonParser.call(node.at_xpath('hours'))
  end
end
