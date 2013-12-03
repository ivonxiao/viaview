local ntm = require "luci.model.network".init()
local wan
local ipaddr
local file

local newline
local index
local strList = {}

local src_dip = "src_dip"
local oldip 

local nameserver = "nameserver"
local dsbu = "dns_set_by_user"
local dnsoption = " option domain-name-servers 210.21.196.6;"
local dns
local olddns
local autodns

    file = io.open("/etc/config/firewall", "r")
    assert(file)
    for line in file:lines() do
        index = string.find(line, src_dip)
        if index then
            i, j = string.find(line,"%d+%.%d+%.%d+%.%d+")
            oldip = string.sub(line, i, j)
        end
    end
    file:close()
    os.execute("/etc/init.d/sysctl restart")


while true do
--autodns
    autodns = true
    dns = nil
    olddns = nil
    file = io.open("/etc/dhcpd.conf", "r")
    assert(file)
    for line in file:lines() do
        index = string.find(line, dsbu)
        if index then
            autodns = false        --dns set by user, do not change
        end
        index = string.find(line, "domain%-name%-servers")
        if index then
            i, j = string.find(line,"%d+%.%d+%.%d+%.%d+")
            olddns = string.sub(line, i, j)
        end
    end
    file:close()

    file = io.open("/etc/resolv.conf", "r")
    assert(file)
    for line in file:lines() do
        index = string.find(line, nameserver)
        if index then
            index = string.find(line, "#")
            if index == nil then
                i, j = string.find(line,"%d+%.%d+%.%d+%.%d+")
                dns = string.sub(line, i, j)
            end
        end
    end
    file:close()
    --print(autodns)
    --print(dns)
    --print(olddns)
    if autodns and dns and dns ~= olddns then
        file = io.open("/etc/dhcpd.conf", "r")
        assert(file)
        local lineindex = 1
        for line in file:lines() do
            if olddns then   -- has dns option
                index = string.find(line, "domain-name-servers")
                if index then
                    index = string.find(line, "#")
                    if index == nil then
                        newline = string.gsub(line, olddns, dns)
                        strList[linedindex] = newline
                    end
                end
            else     --no dns option,must add one
                index = string.find(line, "option%s+routers")    
                if index then
                    index = string.find(line, "#")
                    if index == nil then
                        dnsoption = string.gsub(dnsoption, "210.21.196.6", dns)
                        strList[lineindex] = dnsoption
                        lineindex = lineindex + 1
                        strList[lineindex] = line
                    else
                        strList[lineindex] = line
                    end
                else
                 strList[lineindex] = line
                end
            end
            lineindex = lineindex + 1
        end   --end for
        file:close()

        file = io.open("/etc/dhcpd.conf", "w")
        for i=1, lineindex-1 do
	    file:write(strList[i])
	    file:write('\n')
	    --print(strList[i])
	    --print(i)
        end
        file:close()
        os.execute("/etc/init.d/dhcpd restart")
    end
    
--autoip
    wan = ntm:get_wannet()
    if (wan) then
	    ipaddr  = wan:ipaddr()
	    --print(ipaddr)
	    if ipaddr ~= "192.168.2.1" and ipaddr ~= oldip then
		file = io.open("/etc/config/firewall", "r")
		assert(file)
		
		local is = 1
		for line in file:lines() do
		    index = string.find(line, oldip)
			if index then
				newline = string.gsub(line, oldip, ipaddr)
				strList[is] = newline
			else
			strList[is] = line
			end
			is = is + 1
			--print("cout index = ", count,index)
		    --print(is)
		end
		file:close()

		oldip = ipaddr

		file = io.open("/etc/config/firewall", "w")
		for i=1, is-1 do
		    file:write(strList[i])
		    file:write('\n')
		    --print(strList[i])
		    --print(i)
		end
		file:close()

		os.execute("/etc/init.d/firewall restart")
		os.execute("/etc/init.d/sysctl restart")
	    end
	end
    os.execute("sleep 2")
end
