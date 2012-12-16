module("accelerator", package.seeall)
local json = require("cjson")
local memcached = require("resty.memcached")
local debug
debug = function(kind, msg)
  if msg then
    msg = ": " .. msg
  else
    msg = ""
  end
  return ngx.log(ngx.DEBUG, kind .. msg)
end
local memc
memc = function(opts)
  if opts == nil then
    opts = { }
  end
  local client, err = memcached:new()
  if not client or err then
    error(err or "problem creating client")
  end
  client:set_timeout(1000)
  local ok
  ok, err = client:connect((opts.host or "127.0.0.1"), (opts.port or 11211))
  if not ok or err then
    error(err or "problem connecting")
  end
  return client
end
local writeCache
writeCache = function(opts)
  local co = coroutine.create(function()
    debug("write cache")
    do
      local res = ngx.location.capture(ngx.var.request_uri)
      if res then
        res.time = os.time()
        return memc(opts):set(ngx.var.request_uri, json.encode(res))
      end
    end
  end)
  return coroutine.resume(co)
end
local access
access = function(opts)
  if ngx.var.request_method ~= "GET" then
    return 
  end
  if ngx.is_subrequest then
    return 
  end
  local fn
  fn = function()
    local cache, flags, err = memc(opts):get(ngx.var.request_uri)
    if err then
      error(err)
    end
    if cache then
      debug("read cache", cache)
      cache = json.decode(cache)
      local ttl = nil
      do
        local cc = cache.header["Cache-Control"]
        if cc then
          local x, x
          x, x, ttl = string.find(cc, "max%-age=(%d+)")
        end
      end
      if ttl then
        ttl = tonumber(ttl)
        debug("ttl", ttl)
      end
      if os.time() - cache.time >= (ttl or 10) then
        writeCache(opts)
      end
      ngx.header = cache.header
      ngx.say(cache.body)
      return ngx.exit(ngx.HTTP_OK)
    end
    return writeCache(opts)
  end
  local status, err = pcall(fn)
  if err then
    return ngx.log(ngx.ERR, err)
  end
end
return {
  access = access
}
