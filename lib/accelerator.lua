module("accelerator", package.seeall)
if ngx.var.request_method ~= "GET" then
  return {
    access = function() end,
    body_filter = function() end
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
access = function()
  local cache, flags, err = memc():get(ngx.var.request_uri)
  if err then
    return 
  end
  if cache then
    ngx.log(ngx.ERR, "readCache", cache)
    cache = json.decode(cache)
    if os.time() - cache.time < 10 then
      ngx.headers = cache.headers
      ngx.say(cache.body)
      ngx.exit(ngx.HTTP_OK)
    end
  end
  return cache
end
body_filter = function()
  if ngx.ctx.written then
    return 
  end
  if not ngx.ctx.body then
    ngx.ctx.body = ""
  end
  ngx.ctx.body = ngx.ctx.body .. ngx.arg[1]
  if not ngx.arg[2] then
    return 
  end
  ngx.ctx.written = true
  json = json.encode({
    body = ngx.ctx.body,
    headers = ngx.headers,
    time = os.time()
  })
  ngx.log(ngx.ERR, "writeCache", json)
  return memc():set(ngx.var.request_uri, json)
end
return {
  access = access,
  body_filter = body_filter
}
