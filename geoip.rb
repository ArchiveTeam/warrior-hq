require "net/http"

class GeoIP
  def initialize(hostname: "smart-ip.net", port: 80)
    @hostname = hostname
    @port = port
    @cache = {}
    @cache_timestamp = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def [](ip, cached_only=true)
    current_timestamp = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    if current_timestamp - @cache_timestamp > 3600
      @cache.delete_if {|key, value| value.nil? }
      @cache_timestamp = current_timestamp
    end

    @cache[ip] ||= lookup(ip, cached_only)
  end

  def process_todo
    ips = $redis.smembers("warriorhq:geoip:todo")
    ips.each do |ip|
      puts ip
      lookup(ip, false)
      $redis.srem("warriorhq:geoip:todo", ip)
    end
  end

  private

  def lookup(ip, cached_only)
    data = $redis.hget("warriorhq:geoip", ip)
    if data.nil?
      if cached_only
        $redis.sadd("warriorhq:geoip:todo", ip)
        return nil
      end

      data = Net::HTTP.get(@hostname, "/geoip-json/#{ ip }", @port)
      $redis.hset("warriorhq:geoip", ip, data)
    end
    JSON.parse(data)
  end
end
