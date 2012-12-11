local Accelerator
do
  local _parent_0 = nil
  local _base_0 = {
    readCache = function(self)
      local cache, flags, err = self.memc:get(ngx.var.request_uri)
      if err then
        return 
      end
      if cache then
        ngx.log(ngx.ERR, "readCache", cache)
        cache = json.decode(cache)
        ngx.say(cache.body)
        ngx.exit(ngx.HTTP_OK)
        if os.time() - cache.time >= 10 then
          cache = nil
        end
      end
      return cache
    end,
    writeCache = function(self)
      ngx.log(ngx.ERR, "writeCache")
      local res = ngx.location.capture(ngx.var.request_uri, {
        args = {
          decelerate = "1"
        }
      })
      if res then
        ngx.log(ngx.ERR, "res.body", res.body)
        ngx.say(res.body)
        ngx.exit(ngx.HTTP_OK)
        res.time = os.time()
        local cache = json.encode(res)
        return self.memc:set(ngx.var.request_uri, cache)
      end
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self)
      local params = ngx.req.get_uri_args()
      if ngx.var.request_method ~= "GET" then
        return 
      end
      local err
      self.memc, err = memcached:new()
      if not self.memc then
        return 
      end
      self.memc:set_timeout(1000)
      local ok
      ok, err = self.memc:connect("127.0.0.1", 11211)
      if not ok then
        return 
      end
      if not self:readCache() then
        return self:writeCache()
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
