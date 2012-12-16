#Nginx Accelerator

Drop-in page caching using nginx, lua, and memcached.

##Features

* Listens to Cache-Control max-age header
* The memcached key is the URI (easy to expire on demand)
* Really, really fast

##Requirements

Nginx build with the following modules:

* [LuaJIT](http://wiki.nginx.org/HttpLuaModule)
* [MemcNginxModule](http://wiki.nginx.org/HttpMemcModule)
* [LuaRestyMemcachedLibrary](https://github.com/agentzh/lua-resty-memcached)

See the [Building OpenResty](#building-openresty) section below for instructions.

##Install

    luarocks install nginx-accelerator

##Usage

Drop the following line in any `location` directive within `nginx.conf`:

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

## Building Demo Project

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