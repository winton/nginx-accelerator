class Accelerator
  new: =>
    params = ngx.req.get_uri_args()

    -- Only cache GET requests
    return if ngx.var.request_method ~= "GET"

    -- Create memcached client
    @memc, err = memcached\new()
    return if not @memc

    -- Set memcached connection timeout to 1 sec
    @memc\set_timeout(1000)

    -- Connect to memcached server
    ok, err = @memc\connect("127.0.0.1", 11211)
    return if not ok

    -- Read/write cache
    @writeCache() if not @readCache()

  readCache: =>
    cache, flags, err = @memc\get(ngx.var.request_uri)
    return if err

    if cache
      ngx.log(ngx.ERR, "readCache", cache)
      cache = json.decode(cache)

      ngx.say(cache.body)
      ngx.exit(ngx.HTTP_OK)

      if os.time() - cache.time >= 10
        cache = nil

    cache

  writeCache: =>
    ngx.log(ngx.ERR, "writeCache")

    res = ngx.location.capture(ngx.var.request_uri, args: decelerate: "1")
    if res
      ngx.log(ngx.ERR, "res.body", res.body)

      ngx.say(res.body)
      ngx.exit(ngx.HTTP_OK)
      
      res.time = os.time()
      cache = json.encode(res)
      @memc\set(ngx.var.request_uri, cache)

Accelerator()





-- Execute within body_filter_by_lua:
-- http://wiki.nginx.org/HttpLuaModule#body_filter_by_lua

export body_filter = ->
  return if ngx.ctx.written

  ngx.ctx.body = "" if not ngx.ctx.body
  ngx.ctx.body ..= ngx.arg[1]

  return if not ngx.arg[2]

  ngx.ctx.written = true
  
  json = json.encode({
    body: ngx.ctx.body
    headers: ngx.headers
    time: os.time()
  })

  ngx.log(ngx.ERR, "writeCache", json)
  memc()\set(ngx.var.request_uri, json)