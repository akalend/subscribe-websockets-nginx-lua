# Basic
The subscribe lua script for redis by websocket through nginx


# Requitments

 * lua-nginx-module      https://github.com/openresty/lua-nginx-module/  
 * lua-cjson             https://github.com/openresty/lua-cjson/         
 * lua-resty-websocket   https://github.com/openresty/lua-resty-websocket
 * lua-resty-redis       https://github.com/openresty/lua-resty-redis


# Install

You must to copy lib folder from:

 *	lua-resty-websocket
 *	lua-resty-redis

to /usr/share/nginx/lua or othe path

to include in the http location of nginx.conf:
```
http {
 lua_package_path "/usr/share/nginx/lua/lib/?.lua;;";   
}
```

Create the location for websocket and include file websocket_server.lua:

```
 location /ws { 
            content_by_lua_file /path/to/file/websocket_server.lua; 
        }
```
