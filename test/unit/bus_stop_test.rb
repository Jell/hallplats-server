require File.join(File.dirname(__FILE__),'../test_helper')

class BusStopTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
    #lat: 57.8625413121034
    #lng: 11.9033844682599
  end
  
  test "initialze with Vasttrafik" do
    vasttrafik_stop = BusStop.find(:first, :conditions => {:provider_name => "Vasttrafik"})
    assert vasttrafik_stop.name == "Vasttrafik Name"
    assert vasttrafik_stop.stop_id == "Vasttrafik Id"
    assert vasttrafik_stop.lat == 1.5
    assert vasttrafik_stop.lng == 1.5
    assert vasttrafik_stop.provider_name == "Vasttrafik"
  end
  
  test "initialze with SL" do
    sl_stop = BusStop.find(:first, :conditions => {:provider_name => "StorstockholmsLokaltrafik"})
    assert sl_stop.name == "SL Name"
    assert sl_stop.stop_id == "SL Id"
    assert sl_stop.lat == 1.5
    assert sl_stop.lng == 1.5
    assert sl_stop.provider_name == "StorstockholmsLokaltrafik"
  end
  
  test "test SL module" do
    extend Provider::StorstockholmsLokaltrafik
    puts fetch_stop_with_id("9001")
    assert true
  end
end
