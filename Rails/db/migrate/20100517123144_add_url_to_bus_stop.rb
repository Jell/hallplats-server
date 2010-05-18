class AddUrlToBusStop < ActiveRecord::Migration
  def self.up
    add_column :bus_stops, :url, :string
  end

  def self.down
    remove_column :bus_stops, :url
  end
end
