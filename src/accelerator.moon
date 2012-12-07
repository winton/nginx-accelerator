memcached = require "resty.memcached"

class Accelerator
  new: =>
    return if ngx.var.request_method ~= "GET"

    memc, err = memcached\new()
    return if not memc

    memc\set_timeout(1000) -- 1 sec

    ok, err = memc\connect("127.0.0.1", 11211)
    return if not ok

    cache, flags, err = memc\get(ngx.var.request_uri)

    return if err

    if cache
      ngx.log(ngx.ERR, "CACHE FOUND")
      ngx.say(cache)
    else
      ngx.log(ngx.ERR, "CACHE NOT FOUND")
      res = ngx.location.capture("/app" .. ngx.var.request_uri)
      if res and res.body
        ngx.say(res.body)
        memc\set(ngx.var.request_uri, res.body, 10)

Accelerator()