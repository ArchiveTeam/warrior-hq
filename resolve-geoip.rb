require "rubygems"
require "redis"
require "json"
require "./geoip"

$redis = Redis.new(:db=>1)
GeoIP.new(:hostname=>"127.0.0.1").process_todo
