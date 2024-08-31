require "stringio"
require "zlib"

module WarriorHQ
  class App < Sinatra::Base
    set :protection, false

    get "/" do
      File.read("index.html")
    end

    get "/positions.json" do
      content_type :json
      expires 60, :public, :must_revalidate
      headers["Content-Encoding"] = "gzip"

      gzip_cached("warriorhq:cache:positions.json.gz") do
        keys = $redis.keys("warriorhq:instances:*")
        coords = keys.map do |k|
          ip = $redis.hget(k, "ip")
          pos = nil
          if ip
            geo = $geoip[ip]
            if geo and geo["latitude"] and geo["latitude"]=~/[-.0-9]+/
              pos = [ geo["latitude"].to_i, geo["longitude"].to_i ]
            end
          end
          pos
        end.compact
        JSON.dump(coords)
      end
    end

    get "/stats.json" do
      content_type :json
      expires 60, :public, :must_revalidate
      headers["Content-Encoding"] = "gzip"

      gzip_cached("warriorhq:cache:stats.json.gz") do
        keys = $redis.keys("warriorhq:instances:*")
        coords = keys.map do |k|
          ip = $redis.hget(k, "ip")
          pos = nil
          if ip
            geo = $geoip[ip]
            if geo and geo["latitude"] and geo["latitude"]=~/[-.0-9]+/
              pos = [ geo["latitude"].to_i.to_f + (rand - 0.5), geo["longitude"].to_i.to_f + (rand - 0.5) ]
            end
          end
          pos
        end.compact
        projects = Hash.new(0)
        keys.each do |k|
          projects[(JSON.parse($redis.hget(k, "data") || "{}") || {})["selected_project"] || nil] += 1
        end
        projects = projects.sort_by { |project, count| -count }
        JSON.dump({ "projects"=>projects, "coords"=>coords })
      end
    end

    get "/projects.json" do
      headers["Access-Control-Allow-Origin"] = "*"
      cache_control :no_cache, :no_store

      if params[:callback]
        content_type "application/json-p"
        json_data = $redis.get("warriorhq:projects_json")
        "#{ params[:callback] }(#{ json_data });"
      else
        content_type :json
        expires 60, :public, :must_revalidate
        headers["Content-Encoding"] = "gzip"
        gzip_cached("warriorhq:cache:projects.json.gz") do
          $redis.get("warriorhq:projects_json")
        end
      end
    end

    post "/api/register.json" do
      content_type :json
      data = JSON.parse(request.body.read)
      id = $redis.incr("warriorhq:ids")
      $redis.pipelined do
        key = "warriorhq:instances:#{ id }"
        $redis.hset(key, "ip", request.ip)
        $redis.hset(key, "user_agent", request.user_agent)
        $redis.hset(key, "last_seen", Time.now.to_i)
        $redis.expire(key, 15 * 60)
      end
      JSON.dump({"warrior_id"=>"#{ id }"})
    end

    post "/api/update.json" do
      content_type :json
      data = JSON.parse(request.body.read)
      warrior_id = data["warrior"]["warrior_id"]
      if warrior_id.to_s.empty?
        warrior_id = ("#{ request.ip }/#{ request.user_agent }".hash & 0xffff_ffff) | 0x1f00_0000
      end
      if warrior_id.to_s=~/\A[0-9]+\Z/
        key = "warriorhq:instances:#{ warrior_id }"
        $redis.pipelined do
          $redis.hset(key, "ip", request.ip)
          $redis.hset(key, "user_agent", request.user_agent)
          $redis.hset(key, "last_seen", Time.now.to_i)
          $redis.hset(key, "data", JSON.dump(data["warrior"]))
          $redis.expire(key, 15 * 60)
        end
      end
      $redis.get("warriorhq:projects_json")
    end

    not_found do
      "Not found."
    end

    private

    def gzip_cached(cache_key)
      cached = $redis.get(cache_key)
      if cached.nil?
        cached = StringIO.new.tap do |io|
          gz = Zlib::GzipWriter.new(io)
          begin
            gz.write(yield)
          ensure
            gz.close
          end
        end.string
        $redis.set(cache_key, cached)
        $redis.expire(cache_key, 60)
      end
      cached
    end
  end
end
