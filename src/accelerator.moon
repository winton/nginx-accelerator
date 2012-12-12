module "accelerator", package.seeall


-- Only cache GET requests

if ngx.var.request_method ~= "GET"
  return { access: -> }


-- Dependencies

json      = require "cjson"
memcached = require "resty.memcached"


-- Create memcached client

memc = (opts={}) ->
  client, err = memcached\new()
  return if not client

  -- Set memcached connection timeout to 1 sec
  client\set_timeout(1000)

  -- Connect to memcached server
  ok, err = client\connect((opts.host or "127.0.0.1"), (opts.port or 11211))
  return if not ok

  client


-- Create coroutine to write cache

writeCache = (opts) ->
  co = coroutine.create ->
    ngx.log(ngx.DEBUG, "WRITE CACHE")

    if res = ngx.location.capture(ngx.var.request_uri)
      res.time = os.time()
      memc(opts)\set(ngx.var.request_uri, json.encode(res))

  coroutine.resume(co)


-- Execute within access_by_lua:
-- http://wiki.nginx.org/HttpLuaModule#access_by_lua

export access = (opts) ->
  return if ngx.is_subrequest

  cache, flags, err = memc(opts)\get(ngx.var.request_uri)
  return if err

  if cache
    ngx.log(ngx.DEBUG, "READ CACHE " .. cache)

    cache = json.decode(cache)
    ttl   = nil

    if cc = cache.header["Cache-Control"]
      x, x, ttl = string.find(cc, "max%-age=(%d+)")

    if ttl
      ttl = tonumber(ttl)
      ngx.log(ngx.DEBUG, "TTL ", ttl)

    -- Rewrite cache if ttl expires
    -- Without a default ttl, you get stuck on a caches without Cache-Control
    if os.time() - cache.time >= (ttl or 10)
      writeCache(opts)
    
    ngx.header = cache.header
    ngx.say(cache.body)

    return ngx.exit(ngx.HTTP_OK)
  
  writeCache(opts)


-- Return

return { access: access }