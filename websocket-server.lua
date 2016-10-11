    local server = require "resty.websocket.server"
    local redis = require "resty.redis"
    local cjson = require "cjson"

    local host = "127.0.0.1"
    local port = 6379

    if ngx.var.redis_host then
        host = ngx.var.redis_host
    else    
        ngx.log(ngx.INFO, "the nginx variable redis_host is undefined, use the localhost")
    end
    
    if ngx.var.redis_port then
        port = tonumber(ngx.var.redis_port)
    else    
        ngx.log(ngx.INFO, "the nginx variable redis_port is undefined, use the defaul port 6379")
    end    

    local red = redis:new()

    local ok, err = red:connect(host, ngx.var.redis_port)
    if not ok then
        ngx.log(ngx.ERR,"1: failed to connect: ", err)
        return
    end

    ngx.log( ngx.INFO, "redis: connected")


    local wb, err = server:new{
        timeout = 5000,  -- in milliseconds
        max_payload_len = 65535,
    }

    if not wb then
        ngx.log(ngx.ERR, "failed to new websocket: ", err)
        return ngx.exit(444)
    end
    local data, typ, err = wb:recv_frame()

    if not data then
        ngx.log(ngx.ERR, "failed to receive a frame: ", err)
        return ngx.exit(444)
    end

    if typ == "close" then

        local bytes, err = wb:send_close(1000, "enough, enough!")
        if not bytes then
            ngx.log(ngx.ERR, "failed to send the close frame: ", err)
            return
        end
        local code = err
        ngx.log(ngx.INFO, "closing with status code ", code, " and message ", data)
        return
    end

    if typ == "text" then

        local res, err = red:subscribe(data)
        if not res then
            ngx.log(ngx.ERR,"1: failed to subscribe: ", err)
            
            return
        end

        ngx.log(ngx.INFO,"subscribe: " , cjson.encode(res))

        if not res then
            ngx.log(ngx.ERR,"1: failed to subscribe: ", err)
            
            local bytes, err = wb:send_close(1000, "enough, enough!")
            if not bytes then
                ngx.log(ngx.ERR, "failed to send the close frame: ", err)
                return
            end

            return
        end

        res, err = red:read_reply()
        if not res then
            ngx.log(ngx.ERR,"failed to read reply from redis: ", err)
            return
        end

        ngx.log(ngx.INFO,"subscribe: " , cjson.encode(res))


        wb:set_timeout(1000)  -- change the network timeout to 1 second
        bytes, err = wb:send_text(  res[3] )
        if not bytes then
            ngx.log(ngx.ERR, "failed to send a text frame: ", err)
            return ngx.exit(444)
        end
    else
        ngx.log(ngx.INFO, "received a frame of type ", typ, " and payload ", data)
    end

    wb:set_timeout(100)  -- change the network timeout to 0.1 second


    local bytes, err = wb:send_close(100, "enough, enough!")
    if not bytes then
        ngx.log(ngx.ERR, "failed to send the close frame: ", err)
        return
    end