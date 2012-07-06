require "rubygems"
require "redis"

$redis = Redis.new(:db=>1)
$redis.set("warriorhq:projects_json", File.read(ARGV[0]))

