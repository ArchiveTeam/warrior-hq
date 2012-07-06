require "rubygems"
require "bundler"

Bundler.require

require "./app"

$redis = Redis.new(:db=>1)

run WarriorHQ::App

