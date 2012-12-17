#Nginx Accelerator

Drop-in page caching using nginx, lua, and memcached.

##Features

* Listens to Cache-Control max-age header
* The memcached key is the URI (easy to expire on demand)
* Really, really fast

##Requirements

You'll need an nginx build with the following modules:

* [LuaJIT](http://wiki.nginx.org/HttpLuaModule)
* [MemcNginxModule](http://wiki.nginx.org/HttpMemcModule)
* [LuaRestyMemcachedLibrary](https://github.com/agentzh/lua-resty-memcached)

##Configure nginx

###Install luarock

	git clone git://github.com/winton/nginx-accelerator.git
	cd nginx-accelerator
	luarocks make

###nginx.conf

Drop the following line in any `location` directive:

    access_by_lua "require('accelerator').access()";

For example:

    http {
      server {
        listen 8080;

        location = / {
          access_by_lua "require('accelerator').access()";
        }
      }
    }

The TTL is based on `Cache-Control: max-age`, but defaults to 10 seconds.

To configure your memcached connection information:

	access_by_lua "require('accelerator').access({ host='127.0.0.1', port=11211 })";

## Ruby client

### Install gem

	gem install accelerator

### Example

	cache = Accelerator.new("localhost:11211")
	cache.get("/test")
	cache.set("/test", "body")
	cache.delete("/test")	
	cache.expire("/test", 10)

## Running specs

###Install Lua

	brew install lua
	brew install luarocks

###Install PCRE

	brew update
	brew install pcre

###Install [OpenResty](http://openresty.org) (nginx)

	curl -O http://agentzh.org/misc/nginx/ngx_openresty-1.2.4.9.tar.gz
	tar xzvf ngx_openresty-1.2.4.9.tar.gz
	cd ngx_openresty-1.2.4.9/

Get your PCRE version:

	brew info pcre

Replace **VERSION** below with the PCRE version:

	./configure --with-luajit --with-cc-opt="-I/usr/local/Cellar/pcre/VERSION/include" --with-ld-opt="-L/usr/local/Cellar/pcre/VERSION/lib"
	make
	make install

###Start nginx

	cd nginx-accelerator
	./nginx/start

### Run specs

	bundle install
	spec spec