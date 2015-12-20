wifi.setmode(wifi.STATION)
wifi.sta.setip({
    ip="192.168.1.10",
    netmask="255.255.255.0",
    gateway="192.168.1.254"
})
wifi.sta.config("SSID","Password")

led1 = 1
led2 = 2

-- was 1000
pwm.setup(led1, 50, 0)
pwm.setup(led2, 50, 0)
pwm.start(led1)
pwm.start(led2)

srv = net.createServer(net.TCP)

srv:listen(48080,function(conn)
    conn:on("receive", function(conn,request)
        print(request);
        
        local buffer = "";

        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local _GET = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                _GET[k] = v
            end
        end

        buffer = buffer.."HTTP/1.0 200 OK\n"
        buffer = buffer.."Access-Control-Allow-Origin: *\n\n"

        buffer = buffer.."<html><body>";
        buffer = buffer.."<h1>Flashy Lights</h1>";
        buffer = buffer.."<p><a href=\"?mode=on\"><button>On</button></a></p>";
        buffer = buffer.."<p><a href=\"?mode=blinky\"><button>Blinky</button></a></p>";
        buffer = buffer.."<p><a href=\"?mode=fadey\"><button>Fadey</button></a></p>";
        buffer = buffer.."<p><a href=\"?mode=off\"><button>Off</button></a></p>";
        buffer = buffer.."</body></html>";

        if(_GET.mode == "blinky") then

            value = 1023;
            tmr.alarm(0, 1000, 1, function()
                pwm.setduty(led1, value);
                pwm.setduty(led2, 1023-value);
                if (value == 1023) then value = 0;
                elseif (value == 0) then value = 1023; end
            end )

        elseif(_GET.mode == "fadey") then
            
            value = 1000;
            inc = 1;
            tmr.alarm(0, 1, 1, function()
                pwm.setduty(led1, value);
                pwm.setduty(led2, 1023-value+500);
                value = value + inc;
                if (value == 1023) then inc = -inc; 
                elseif (value == 500) then inc = -inc; end
            end )

        elseif(_GET.mode == "on") then
            
            tmr.stop(0);
            pwm.setduty(led1, 1023);
            pwm.setduty(led2, 1023);

        elseif(_GET.mode == "off") then
            
            tmr.stop(0);
            pwm.setduty(led1, 0);
            pwm.setduty(led2, 0);

        end

        local timeout = tonumber(_GET.timer);
        if (timeout ~= nil and timeout > 0) then
            tmr.alarm(6, timeout, 0, function()
                tmr.stop(0);
                pwm.setduty(led1, 0);
                pwm.setduty(led2, 0);
            end )
        end

        conn:send(buffer);
        conn:close();
    end)
end)