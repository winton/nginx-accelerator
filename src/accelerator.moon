module "accelerator", package.seeall

-- Only cache GET requests

if ngx.var.request_method ~= "GET"
  return {
    access: ->
    body_filter: ->
  }


-- Dependencies

json      = require "cjson"
memcached = require "resty.memcached"


-- Create memcached client

memc = ->
  client, err = memcached\new()
  return if not client

  -- Set memcached connection timeout to 1 sec
  client\set_timeout(1000)

  -- Connect to memcached server
  ok, err = client\connect("127.0.0.1", 11211)
  return if not ok

  client


-- Execute within access_by_lua:
-- http://wiki.nginx.org/HttpLuaModule#access_by_lua

export access = ->
  cache, flags, err = memc()\get(ngx.var.request_uri)
  return if err

  if cache
    ngx.log(ngx.ERR, "readCache", cache)
    cache = json.decode(cache)

    -- Serve up cache if ttl  < 10 seconds
    if os.time() - cache.time < 10
      ngx.headers = cache.headers
      ngx.say(cache.body)
      ngx.exit(ngx.HTTP_OK)

  cache


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


-- Return

return {
  access: access
  body_filter: body_filter
}