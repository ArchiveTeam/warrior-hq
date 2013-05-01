require "rubygems"
require "redis"
require "json"
require File.join(File.dirname(__FILE__), "./geoip")

$redis = Redis.new(:db=>1)

data = JSON.parse(File.read(ARGV[0]).gsub(/^\/\/.+/, ""))
data["projects"].compact!
data["projects"].each do |project|
  if project["host"] and not project["lat_lng"]
    geo = GeoIP.new[project["host"], false]
    if geo and geo["latitude"] and geo["latitude"]=~/[-.0-9]+/
      project["lat_lng"] = [ geo["latitude"].to_i, geo["longitude"].to_i ]
    end
  end
end

$redis.set("warriorhq:projects_json", JSON.dump(data))

