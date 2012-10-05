require "net/http"

class GeoIP
  def initialize
    @cache = {}
  end

  def [](ip)
    @cache[ip] ||= lookup(ip)
  end

  private

  def lookup(ip)
    data = $redis.hget("warriorhq:geoip", ip)
    if data.nil?
      data = Net::HTTP.get("smart-ip.net", "/geoip-json/#{ ip }")
      $redis.hset("warriorhq:geoip", ip, data)
    end
    JSON.parse(data)
  end
end

