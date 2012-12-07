local memcached = require("resty.memcached")
local Accelerator
do
  local _parent_0 = nil
  local _base_0 = { }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self)
      if ngx.var.request_method ~= "GET" then
        return 
      end
      local memc, err = memcached:new()
      if not memc then
        return 
      end
      memc:set_timeout(1000)
      local ok
      ok, err = memc:connect("127.0.0.1", 11211)
      if not ok then
        return 
      end
      local cache, flags
      cache, flags, err = memc:get(ngx.var.request_uri)
      if err then
        return 
      end
      if cache then
        ngx.log(ngx.ERR, "CACHE FOUND")
        return ngx.say(cache)
      else
        ngx.log(ngx.ERR, "CACHE NOT FOUND")
        local res = ngx.location.capture("/app" .. ngx.var.request_uri)
        if res and res.body then
          ngx.say(res.body)
          return memc:set(ngx.var.request_uri, res.body, 10)
        end
      end
    end,
    __base = _base_0,
    __name = "Accelerator",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Accelerator = _class_0
end
return Accelerator()
