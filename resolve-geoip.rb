require "rubygems"
require "redis"
require "json"
require "./geoip"

$redis = Redis.new(:db=>1)
GeoIP.new(:hostname=>"127.0.0.1",:port=>8345).process_todo
