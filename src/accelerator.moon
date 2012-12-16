module "accelerator", package.seeall


-- Dependencies

json      = require "cjson"
memcached = require "resty.memcached"


-- Debug log

debug = (kind, msg) ->
  msg = if msg then ": " .. msg else ""
  ngx.log(ngx.DEBUG, kind .. msg)


-- Create memcached client

memc = (opts={}) ->
  client, err = memcached\new()
  error(err or "problem creating client") if not client or err

  -- Set memcached connection timeout to 1 sec
  client\set_timeout(1000)

  -- Connect to memcached server
  ok, err = client\connect((opts.host or "127.0.0.1"), (opts.port or 11211))
  error(err or "problem connecting") if not ok or err

  client


-- Create coroutine to write cache

writeCache = (opts) ->
  co = coroutine.create ->
    debug("write cache")

    if res = ngx.location.capture(ngx.var.request_uri)
      res.time = os.time()
      memc(opts)\set(ngx.var.request_uri, json.encode(res))

  coroutine.resume(co)


-- Execute within access_by_lua:
-- http://wiki.nginx.org/HttpLuaModule#access_by_lua

access = (opts) ->
  return if ngx.var.request_method ~= "GET"
  return if ngx.is_subrequest

  fn = ->
    cache, flags, err = memc(opts)\get(ngx.var.request_uri)
    error(err) if err

    if cache
      debug("read cache", cache)

      cache = json.decode(cache)
      ttl   = nil

      if cc = cache.header["Cache-Control"]
        x, x, ttl = string.find(cc, "max%-age=(%d+)")

      if ttl
        ttl = tonumber(ttl)
        debug("ttl", ttl)

      -- Rewrite cache if ttl expires
      -- Without a default ttl, you get stuck on a caches without Cache-Control
      if os.time() - cache.time >= (ttl or 10)
        writeCache(opts)
      
      ngx.header = cache.header
      ngx.say(cache.body)

      return ngx.exit(ngx.HTTP_OK)
    
    writeCache(opts)

  status, err = pcall(fn)
  ngx.log(ngx.ERR, err) if err


-- Return

return { access: access }