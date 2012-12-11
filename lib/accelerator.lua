module("accelerator", package.seeall)
if ngx.var.request_method ~= "GET" then
  return {
    access = function() end
  }
end
local json = require("cjson")
local memcached = require("resty.memcached")
local memc
memc = function()
  local client, err = memcached:new()
  if not client then
    return 
  end
  client:set_timeout(1000)
  local ok
  ok, err = client:connect("127.0.0.1", 11211)
  if not ok then
    return 
  end
  return client
end
local writeCache
writeCache = function()
  local co = coroutine.create(function()
    do
      local res = ngx.location.capture(ngx.var.request_uri)
      if res then
        res.time = os.time()
        return memc():set(ngx.var.request_uri, json.encode(res))
      end
    end
  end)
  return coroutine.resume(co)
end
access = function()
  if ngx.is_subrequest then
    return 
  end
  local cache, flags, err = memc():get(ngx.var.request_uri)
  if err then
    return 
  end
  if cache then
    ngx.log(ngx.ERR, "readCache", cache)
    cache = json.decode(cache)
    do
      local cc = cache.header["Cache-Control"]
      if cc then
        local x, x, ttl = string.find(cc, "max%-age=(%d+)")
      end
    end
    if os.time() - cache.time >= (ttl or 10) then
      writeCache()
    end
    ngx.header = cache.header
    ngx.say(cache.body)
    return ngx.exit(ngx.HTTP_OK)
  end
end
return {
  access = access
}
