require "rubygems"
require "bundler"

Bundler.require

require "./geoip"
require "./app"

$redis = Redis.new(:db=>1)
$geoip = GeoIP.new

run WarriorHQ::App

