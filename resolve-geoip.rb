require "rubygems"
require "redis"
require "json"
require "./geoip"

$redis = Redis.new(:db=>1)
GeoIP.new.process_todo

