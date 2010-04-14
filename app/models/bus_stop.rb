class BusStop < ActiveRecord::Base
  validates_presence_of :name, :lat, :lng, :stop_id, :provider_name
  
  after_initialize :extend_module

  def forecast
    url = get_forecast_url(stop_id)
    return {:url => url, :forecast_parser => lambda {|response| parse_forecast(response, stop_id, name)}}
    #return parse_forecast(response, stop_id, name)
  end
  
  def url
    get_forecast_url(stop_id)
  end
  
  private
  def extend_module
    #self.extend Provider::Vasttrafik
    self.extend "Provider::#{provider_name}".constantize
  end
  
end
