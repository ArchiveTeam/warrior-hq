require "rubygems"
require "bundler"

Bundler.require

require "./geoip"
require "./app"

$redis = Redis.new(:db=>1)
$geoip = GeoIP.new(:hostname=>"127.0.0.1")

run WarriorHQ::App
