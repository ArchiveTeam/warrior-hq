module WarriorHQ
  class App < Sinatra::Base
    post "/api/register.json" do
      content_type :json
      data = JSON.parse(request.body.read)
      id = $redis.incr("warriorhq:ids")
      $redis.pipelined do
        key = "warriorhq:instances:#{ id }"
        $redis.hset(key, "ip", request.ip)
        $redis.hset(key, "last_seen", Time.now.to_i)
        $redis.expire(key, 15 * 60)
      end
      JSON.dump({"warrior_id"=>"#{ id }"})
    end

    post "/api/update.json" do
      content_type :json
      data = JSON.parse(request.body.read)
      if data["warrior"]["warrior_id"].to_s=~/\A[0-9]+\Z/
        key = "warriorhq:instances:#{ data["warrior"]["warrior_id"] }"
        $redis.pipelined do
          $redis.hset(key, "ip", request.ip)
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
  end
end

