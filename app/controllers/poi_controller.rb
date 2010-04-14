class PoiController < ApplicationController  
  def index
    #tic = Time.now
    lat = Float params[:lat]
    lng = Float params[:lng]
    stop_list = get_nearest_stops(lat,lng)
    result = []
    hydra = Typhoeus::Hydra.new
    hydra.disable_memoization
    
    stop_list.each do |element|
      attributes = {}
      attributes[:name] = element.name
      attributes[:lat] = element.lat
      attributes[:lng] = element.lng
      
      forecast_bundle = element.forecast;
      n_retry = 20;
      parallel_req = Typhoeus::Request.new(forecast_bundle[:url], :timeout => 1000)
      parallel_req.on_complete do |response|
        attributes[:forecast] = forecast_bundle[:forecast_parser].call(response.body)
        if n_retry > 0 && attributes[:forecast] == []
          hydra.queue parallel_req
          n_retry -= 1
        end
      end
      hydra.queue parallel_req
      result << attributes
    end
    
    begin
      Timeout::timeout(8) do
        hydra.run
      end
    rescue Timeout::Error
      #puts "Too slow!"
    end
    
    #tac = Time.now
    #puts(tac - tic)
    respond_to do |format|
      format.json  { render :json => result.to_json }
      format.text  { render :text => result.to_json }
    end
  end
  
  private
  def get_nearest_stops(lat,lng)
    area = 0.002
    list = BusStop.where(["lat > ? AND lat < ? AND lng > ? AND lng < ?", lat - area, lat + area, lng- area, lng + area])
    while list.count < 10 do
      list = list + BusStop.where(["lat > ? AND lat < ? AND lng > ? AND lng < ? AND NOT (lat > ? AND lat < ? AND lng > ? AND lng < ?)", lat - 2*area, lat + 2*area, lng- 2*area, lng + 2*area, lat - area, lat + area, lng- area, lng + area])
      area = area * 2
    end
    return sort_stops(list, lat, lng).first(10)
  end
  
  def sort_stops(list, lat, lng)
    #sort by distance to origin
    list.sort! do |a,b|
      distance_geodesic(Float(a.lat), Float(a.lng), lat, lng) <=> distance_geodesic(Float(b.lat), Float(b.lng), lat, lng)
      #(Float(a.lat) - lat) ** 2 + (Float(a.lng) -lng) ** 2 <=> (Float(b.lat) - lat) ** 2 + (Float(b.lng) -lng) ** 2
    end
    return list
  end
  
  def distance_geodesic(lat1, long1, lat2, long2)
    #convert from degrees to radians
    a1 = lat1 * (Math::PI / 180)
    b1 = long1 * (Math::PI / 180)
    a2 = lat2 * (Math::PI / 180)
    b2 = long2 * (Math::PI / 180)

    r = 6356.75 #radius of earth
    #do the calculation with radians as units
    d = r * Math.acos(Math.cos(a1)*Math.cos(b1)*Math.cos(a2)*Math.cos(b2) + Math.cos(a1)*Math.sin(b1)*Math.cos(a2)*Math.sin(b2) + Math.sin(a1)*Math.sin(a2));
    
  end
end
