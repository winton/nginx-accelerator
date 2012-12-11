#Nginx Accelerator

Drop nginx-level memcached page caching in front of any route.

* Listens to Cache-Control max-age header
* The memcached key is the URI (easy to expire on demand)

##Install

    luarocks install nginx-accelerator

##Usage

Let's say you wanted to cache your front page:

    http {
	    server {
		    listen 8080;

		    location = / {

			    header_filter_by_lua 'ngx.header["Cache-Control"] = "max-age=10"';
			    access_by_lua "require('accelerator').access()";
		    }
	    }
    }