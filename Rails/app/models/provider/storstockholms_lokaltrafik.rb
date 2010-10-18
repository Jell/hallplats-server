# coding: utf-8
module Provider::StorstockholmsLokaltrafik
  include Provider::Base

  def update_stop_database
    provider_name = "StorstockholmsLokaltrafik"
    for stop_id in 0000..9999 do
      a_stop = fetch_stop_with_id("%04d" % stop_id)
      if not a_stop == nil
        test_valid = get_forecast("%04d" % stop_id, a_stop[:name]) != []
        if test_valid
          bus_stop = BusStop.find_or_initialize_by_stop_id_and_provider_name("%04d" % stop_id, provider_name)
          bus_stop.provider_name = provider_name
          bus_stop.name          = a_stop[:name]
          bus_stop.lat           = a_stop[:lat]
          bus_stop.lng           = a_stop[:lng]
          bus_stop.url           = get_forecast_url("%04d" % stop_id)
          bus_stop.touch # ?
          bus_stop.save
        end
      end
    end
    delete_obsolete_stops(provider_name)
  end

  def get_forecast_url(poi_id)
    #url = "http://realtid.sl.se/?epslanguage=SV&WbSgnMdl="+poi_id+"-U3Rv-_-1-_-1-1"
    url = "http://www1.sl.se/realtidws/RealTimeService.asmx/GetDpsDepartures?siteId=" + poi_id + "&timeWindow=60"
  end
  
  def parse_forecast(response, poi_id, poi_name)
    #html_tree = Nokogiri::HTML(response)
    
    xml_tree = Nokogiri::XML.parse(response, nil, 'UTF-8')

    lines = []

    buses = xml_tree.css("Buses").css("DpsBus")
    metros = xml_tree.css("Metros").css("DpsMetro")
    trains = xml_tree.css("Trains").css("DpsTrain")
    trams = xml_tree.css("Trams").css("DpsTram")
    
    # find Bus Forecasts #############################################
    bus_list = {}
    buses.each do |bus|
      line = bus.css("LineNumber").text
      destination = bus.css("Destination").text
      bus_list[{:line => line, :destination => destination}] ||= []
      bus_list[{:line => line, :destination => destination}] |= [format_time(bus.css("DisplayTime").text)]
    end
    
    bus_list.each do |id, departures|
      attributes = {}
      attributes[:line_number]       = id[:line]
      attributes[:color]             = "#FFFFFF"
      attributes[:background_color]  = "#BB0000"
      attributes[:destination]       = id[:destination]
      attributes[:next_trip]         = "#{departures[0]}"
      attributes[:next_handicap]        = false
      attributes[:next_low_floor]       = false
      attributes[:next_next_trip]       = "#{departures[1]}"
      attributes[:next_next_handicap]        = false
      attributes[:next_next_low_floor]       = false

      lines << [attributes[:line_number], attributes]
    end


    # find Metro Forecasts #############################################
    colors = {"10" => "#0080FF",
          "11" => "#0080FF",
          "13" => "#FF0000",
          "14" => "#FF0000",
          "17" => "#00BB00",
          "18" => "#00BB00",
          "19" => "#00BB00"}
          
    metro_list = {}
    metros.each do |metro|
      line = metro.css("LineNumber").text
      destination = metro.css("Destination").text
      metro_list[{:line => line, :destination => destination}] ||= []
      metro_list[{:line => line, :destination => destination}] |= [format_time(metro.css("DisplayTime").text)]
    end

    metro_list.each do |id, departures|
      attributes = {}
      attributes[:line_number]       = "T" + id[:line]
      attributes[:color]             = "#FFFFFF"
      attributes[:background_color]  = colors[id[:line]]
      attributes[:destination]       = id[:destination]
      attributes[:next_trip]         = "#{departures[0]}"
      attributes[:next_handicap]        = false
      attributes[:next_low_floor]       = false
      attributes[:next_next_trip]       = "#{departures[1]}"
      attributes[:next_next_handicap]        = false
      attributes[:next_next_low_floor]       = false

      lines << [attributes[:line_number], attributes]
    end
    
    #find train forecast#############################################
    train_list = {}
    trains.each do |train|
      line = train.css("LineNumber").text
      destination = train.css("Destination").text
      train_list[{:line => line, :destination => destination}] ||= []
      train_list[{:line => line, :destination => destination}] |= [format_time(train.css("DisplayTime").text)]
    end
    
    train_list.each do |id, departures|
      attributes = {}
      attributes[:line_number]       = "P" + id[:line]
      attributes[:color]             = "#FFFFFF"
      attributes[:background_color]  = "#000000"
      attributes[:destination]       = id[:destination]
      attributes[:next_trip]         = "#{departures[0]}"
      attributes[:next_handicap]        = false
      attributes[:next_low_floor]       = false
      attributes[:next_next_trip]       = "#{departures[1]}"
      attributes[:next_next_handicap]        = false
      attributes[:next_next_low_floor]       = false

      lines << [attributes[:line_number], attributes]
    end
    
    #find tram forecast#############################################
    colors = {"7" => "#FFFFFF",
              "12" => "#008457",
              "21" => "#BF2A37",
              "22" => "#F8981C",
              "25" => "#691F7E",
              "26" => "#691F7E",
              "27" => "#007CC3",
              "28" => "#007CC3",
              "29" => "#007CC3"}

    tram_list = {}
    trams.each do |tram|
      line = tram.css("LineNumber").text
      destination = tram.css("Destination").text
      tram_list[{:line => line, :destination => destination}] ||= []
      tram_list[{:line => line, :destination => destination}] |= [format_time(tram.css("DisplayTime").text)]
    end

    tram_list.each do |id, departures|
      attributes = {}
      attributes[:line_number]       = "T" + id[:line]
      attributes[:color]             = (id[:line] == 7 ? "#000000" : "#FFFFFF")
      attributes[:background_color]  = colors[id[:line]]
      attributes[:destination]       = id[:destination]
      attributes[:next_trip]         = "#{departures[0]}"
      attributes[:next_handicap]        = false
      attributes[:next_low_floor]       = false
      attributes[:next_next_trip]       = "#{departures[1]}"
      attributes[:next_next_handicap]        = false
      attributes[:next_next_low_floor]       = false

      lines << [attributes[:line_number], attributes]
    end
    return sort_lines(lines)
  end
  
  private
  
  def fetch_stop_with_id(id)
    Time.zone = "Stockholm"
    params = {
      "REQ0HafasSearchForw"	=>"1",
      "REQ0JourneyDate"			=>Time.zone.now.strftime("%d.%m.%Y"),
      "REQ0JourneyStopsS0A"	=>"255",
      "REQ0JourneyStopsS0G"	=>id,
      "REQ0JourneyStopsSID"	=>"",
      "REQ0JourneyStopsZ0A"	=>"255",
      "REQ0JourneyStopsZ0G"	=>"",
      "REQ0JourneyStopsZID"	=>"",
      "REQ0JourneyTime"			=>Time.zone.now.strftime("%H:%M"),
      "existUnsharpSearch"	=>"yes",
      "ignoreTypeCheck"			=>"yes",
      "queryPageDisplayed"	=>"no",
      "start"						    =>"Sök resa",
      "start.x"						  =>"0",
      "start.y"						  =>"0"
    }

    x = Net::HTTP.post_form(URI.parse("http://reseplanerare.sl.se/bin/query.exe/sn"), params)
    html_tree = Nokogiri::HTML(x.body)

    error = html_tree.xpath('//label[@class="ErrorText"]')

    return nil unless error.empty?

    form = html_tree.xpath('//div[@class="FieldRow"]').first
    name = form.css("strong").text

    latlong_unparsed = form.xpath('//input[@type="submit"]').attribute("name").value

    lat = nil
    lng = nil
    latlong_unparsed.split('&').each do |element|
      attribute = element.split('=')
      if(attribute[0] == "REQMapRoute0.Location0.Y")
        lat = Float(attribute[1])
      end
      if(attribute[0] == "REQMapRoute0.Location0.X")
        lng = Float(attribute[1])
      end
    end

    attributes = {}
    attributes[:name] = name.split(" (")[0]
    attributes[:lat] = lat / 1000000
    attributes[:lng] = lng / 1000000
    attributes[:stop_id] = id

    return attributes
  end
  
  def format_time(string)
    return string.scan(/\d+/).first.to_i if string =~ /\d+ min/
    return nil unless string =~ /\d+:\d\d/
    Time.zone = "Stockholm"
    splited_time = string.split(":")
    hours = splited_time[0].to_i
    minutes = splited_time[1].to_i
    60*(hours - Time.zone.now.hour) + (minutes - Time.zone.now.min)
  end

end
