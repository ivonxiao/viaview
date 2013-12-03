--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.admin.network", package.seeall)

function index()
	local uci = require("luci.model.uci").cursor()
	local page

	page = node("admin", "network")
	page.target = firstchild()
	page.title  = _("LAN")
	page.order  = 50
	page.index  = true
--[[
--	if page.inreq then
		local has_switch = false

		uci:foreach("network", "switch",
			function(s)
				has_switch = true
				return false
			end)

		if has_switch then
			page  = node("admin", "network", "vlan")
			page.target = cbi("admin_network/vlan")
			page.title  = _("Switch")
			page.order  = 20

			page = entry({"admin", "network", "switch_status"}, call("switch_status"), nil)
			page.leaf = true
		end


		local has_wifi = false

		uci:foreach("wireless", "wifi-device",
			function(s)
				has_wifi = true
				return false
			end)

		if has_wifi then
			page = entry({"admin", "network", "wireless_join"}, call("wifi_join"), nil)
			page.leaf = true

			page = entry({"admin", "network", "wireless_add"}, call("wifi_add"), nil)
			page.leaf = true

			page = entry({"admin", "network", "wireless_delete"}, call("wifi_delete"), nil)
			page.leaf = true

			page = entry({"admin", "network", "wireless_status"}, call("wifi_status"), nil)
			page.leaf = true

			page = entry({"admin", "network", "wireless_reconnect"}, call("wifi_reconnect"), nil)
			page.leaf = true

			page = entry({"admin", "network", "wireless_shutdown"}, call("wifi_shutdown"), nil)
			page.leaf = true

			page = entry({"admin", "network", "wireless"}, arcombine(template("admin_network/wifi_overview"), cbi("admin_network/wifi")), _("Wifi"), 15)
			page.leaf = true
			page.subindex = true

			if page.inreq then
				local wdev
				local net = require "luci.model.network".init(uci)
				for _, wdev in ipairs(net:get_wifidevs()) do
					local wnet
					for _, wnet in ipairs(wdev:get_wifinets()) do
						entry(
							{"admin", "network", "wireless", wnet:id()},
							alias("admin", "network", "wireless"),
							wdev:name() .. ": " .. wnet:shortname()
						)
					end
				end
			end
		end

	]]--
		--page = entry({"admin", "network", "iface_add"}, cbi("admin_network/iface_add"), nil)
		--page.leaf = true

		--page = entry({"admin", "network", "iface_delete"}, call("iface_delete"), nil)
		--page.leaf = true
		page = entry({"admin","network","dhcpv4"},template("admin_network/DHCPv4Server"),_("DHCP Server Setting"),60)
		page = entry({"admin","network","dhcpv6"},template("admin_network/DHCPv6Server"),_("DHCPv6 Server Setting"),70)
		page = entry({"admin", "network", "DHCPConfigSave"}, call("dhcpconfig_save"), nil)
		page.leaf = true
		page = entry({"admin", "network", "iface_status"}, call("iface_status"), nil)
		page.leaf = true

		page = entry({"admin", "network", "iface_reconnect"}, call("iface_reconnect"), nil)
		page.leaf = true

		page = entry({"admin", "network", "iface_shutdown"}, call("iface_shutdown"), nil)
		page.leaf = true

		page = entry({"admin", "network", "network"}, arcombine(cbi("admin_network/network"), cbi("admin_network/ifaces")), _("Interfaces"), 10)
		page.leaf   = true
		page.subindex = true
		--[[
		if page.inreq then
			uci:foreach("network", "interface",
				function (section)
					local ifc = section[".name"]
					if ifc ~= "loopback" then
						entry({"admin", "network", "network", ifc},
						true, ifc:upper())
					end
				end)
		end
		]]--
	--[[
		if nixio.fs.access("/etc/config/dhcp") then
			page = node("admin", "network", "dhcp")
			page.target = cbi("admin_network/dhcp")
			page.title  = _("DHCP and DNS")
			page.order  = 30

			page = entry({"admin", "network", "dhcplease_status"}, call("lease_status"), nil)
			page.leaf = true

			page = node("admin", "network", "hosts")
			page.target = cbi("admin_network/hosts")
			page.title  = _("Hostnames")
			page.order  = 40
		end

		page  = node("admin", "network", "routes")
		page.target = cbi("admin_network/routes")
		page.title  = _("Static Routes")
		page.order  = 50

		page = node("admin", "network", "diagnostics")
		page.target = template("admin_network/diagnostics")
		page.title  = _("Diagnostics")
		page.order  = 60

		page = entry({"admin", "network", "diag_ping"}, call("diag_ping"), nil)
		page.leaf = true

		page = entry({"admin", "network", "diag_nslookup"}, call("diag_nslookup"), nil)
		page.leaf = true

		page = entry({"admin", "network", "diag_traceroute"}, call("diag_traceroute"), nil)
		page.leaf = true

		page = entry({"admin", "network", "diag_ping6"}, call("diag_ping6"), nil)
		page.leaf = true

		page = entry({"admin", "network", "diag_traceroute6"}, call("diag_traceroute6"), nil)
		page.leaf = true
		]]--
--	end
end

function wifi_join()
	local function param(x)
		return luci.http.formvalue(x)
	end

	local function ptable(x)
		x = param(x)
		return x and (type(x) ~= "table" and { x } or x) or {}
	end

	local dev  = param("device")
	local ssid = param("join")

	if dev and ssid then
		local cancel  = (param("cancel") or param("cbi.cancel")) and true or false

		if cancel then
			luci.http.redirect(luci.dispatcher.build_url("admin/network/wireless_join?device=" .. dev))
		else
			local cbi = require "luci.cbi"
			local tpl = require "luci.template"
			local map = luci.cbi.load("admin_network/wifi_add")[1]

			if map:parse() ~= cbi.FORM_DONE then
				tpl.render("header")
				map:render()
				tpl.render("footer")
			end
		end
	else
		luci.template.render("admin_network/wifi_join")
	end
end

function wifi_add()
	local dev = luci.http.formvalue("device")
	local ntm = require "luci.model.network".init()

	dev = dev and ntm:get_wifidev(dev)

	if dev then
		local net = dev:add_wifinet({
			mode       = "ap",
			ssid       = "OpenWrt",
			encryption = "none"
		})

		ntm:save("wireless")
		luci.http.redirect(net:adminlink())
	end
end

function wifi_delete(network)
	local ntm = require "luci.model.network".init()
	local wnet = ntm:get_wifinet(network)
	if wnet then
		local dev = wnet:get_device()
		local nets = wnet:get_networks()
		if dev then
			luci.sys.call("env -i /sbin/wifi down %q >/dev/null" % dev:name())
			ntm:del_wifinet(network)
			ntm:commit("wireless")
			local _, net
			for _, net in ipairs(nets) do
				if net:is_empty() then
					ntm:del_network(net:name())
					ntm:commit("network")
				end
			end
			luci.sys.call("env -i /sbin/wifi up %q >/dev/null" % dev:name())
		end
	end

	luci.http.redirect(luci.dispatcher.build_url("admin/network/wireless"))
end

function iface_status(ifaces)
	local netm = require "luci.model.network".init()
	local rv   = { }

	local iface
	for iface in ifaces:gmatch("[%w%.%-_]+") do
		local net = netm:get_network(iface)
		local device = net and net:get_interface()
		if device then
			local data = {
				id         = iface,
				proto      = net:proto(),
				uptime     = net:uptime(),
				gwaddr     = net:gwaddr(),
				dnsaddrs   = net:dnsaddrs(),
				name       = device:shortname(),
				type       = device:type(),
				ifname     = device:name(),
				macaddr    = device:mac(),
				is_up      = device:is_up(),
				rx_bytes   = device:rx_bytes(),
				tx_bytes   = device:tx_bytes(),
				rx_packets = device:rx_packets(),
				tx_packets = device:tx_packets(),

				ipaddrs    = { },
				ip6addrs   = { },
				subdevices = { }
			}

			local _, a
			for _, a in ipairs(device:ipaddrs()) do
				data.ipaddrs[#data.ipaddrs+1] = {
					addr      = a:host():string(),
					netmask   = a:mask():string(),
					prefix    = a:prefix()
				}
			end
			for _, a in ipairs(device:ip6addrs()) do
				if not a:is6linklocal() then
					data.ip6addrs[#data.ip6addrs+1] = {
						addr      = a:host():string(),
						netmask   = a:mask():string(),
						prefix    = a:prefix()
					}
				end
			end

			for _, device in ipairs(net:get_interfaces() or {}) do
				data.subdevices[#data.subdevices+1] = {
					name       = device:shortname(),
					type       = device:type(),
					ifname     = device:name(),
					macaddr    = device:mac(),
					macaddr    = device:mac(),
					is_up      = device:is_up(),
					rx_bytes   = device:rx_bytes(),
					tx_bytes   = device:tx_bytes(),
					rx_packets = device:rx_packets(),
					tx_packets = device:tx_packets(),
				}
			end

			rv[#rv+1] = data
		else
			rv[#rv+1] = {
				id   = iface,
				name = iface,
				type = "ethernet"
			}
		end
	end

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end

function iface_reconnect(iface)
	local netmd = require "luci.model.network".init()
	local net = netmd:get_network(iface)
	if net then
		luci.sys.call("env -i /sbin/ifup %q >/dev/null 2>/dev/null" % iface)
		luci.http.status(200, "Reconnected")
		return
	end

	luci.http.status(404, "No such interface")
end

function iface_shutdown(iface)
	local netmd = require "luci.model.network".init()
	local net = netmd:get_network(iface)
	if net then
		luci.sys.call("env -i /sbin/ifdown %q >/dev/null 2>/dev/null" % iface)
		luci.http.status(200, "Shutdown")
		return
	end

	luci.http.status(404, "No such interface")
end

function iface_delete(iface)
	local netmd = require "luci.model.network".init()
	local net = netmd:del_network(iface)
	if net then
		luci.sys.call("env -i /sbin/ifdown %q >/dev/null 2>/dev/null" % iface)
		luci.http.redirect(luci.dispatcher.build_url("admin/network/network"))
		netmd:commit("network")
		netmd:commit("wireless")
		return
	end

	luci.http.status(404, "No such interface")
end

function wifi_status(devs)
	local s    = require "luci.tools.status"
	local rv   = { }

	local dev
	for dev in devs:gmatch("[%w%.%-]+") do
		rv[#rv+1] = s.wifi_network(dev)
	end

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end

local function wifi_reconnect_shutdown(shutdown, wnet)
	local netmd = require "luci.model.network".init()
	local net = netmd:get_wifinet(wnet)
	local dev = net:get_device()
	if dev and net then
		luci.sys.call("env -i /sbin/wifi down >/dev/null 2>/dev/null")

		dev:set("disabled", nil)
		net:set("disabled", shutdown and 1 or nil)
		netmd:commit("wireless")

		luci.sys.call("env -i /sbin/wifi up >/dev/null 2>/dev/null")
		luci.http.status(200, shutdown and "Shutdown" or "Reconnected")

		return
	end

	luci.http.status(404, "No such radio")
end

function wifi_reconnect(wnet)
	wifi_reconnect_shutdown(false, wnet)
end

function wifi_shutdown(wnet)
	wifi_reconnect_shutdown(true, wnet)
end

function lease_status()
	local s = require "luci.tools.status"

	luci.http.prepare_content("application/json")
	luci.http.write('[')
	luci.http.write_json(s.dhcp_leases())
	luci.http.write(',')
	luci.http.write_json(s.dhcp6_leases())
	luci.http.write(']')
end

function switch_status(switches)
	local s = require "luci.tools.status"

	luci.http.prepare_content("application/json")
	luci.http.write_json(s.switch_status(switches))
end

function diag_command(cmd, addr)
	if addr and addr:match("^[a-zA-Z0-9%-%.:_]+$") then
		luci.http.prepare_content("text/plain")

		local util = io.popen(cmd % addr)
		if util then
			while true do
				local ln = util:read("*l")
				if not ln then break end
				luci.http.write(ln)
				luci.http.write("\n")
			end

			util:close()
		end

		return
	end

	luci.http.status(500, "Bad address")
end

function diag_ping(addr)
	diag_command("ping -c 5 -W 1 %q 2>&1", addr)
end

function diag_traceroute(addr)
	diag_command("traceroute -q 1 -w 1 -n %q 2>&1", addr)
end

function diag_nslookup(addr)
	diag_command("nslookup %q 2>&1", addr)
end

function diag_ping6(addr)
	diag_command("ping6 -c 5 %q 2>&1", addr)
end

function diag_traceroute6(addr)
	diag_command("traceroute6 -q 1 -w 2 -n %q 2>&1", addr)
end
-- save dhcp server configuration 
function dhcpconfig_save()
	local k,v
	local query,start,end_pos
	local sep='<=='
	local sep_len=#sep
	json=require "luci.json"	 

	--request='{"dhcp":1,"eth1":{"option":0,"className":\"test\","idType":1,"valueType":1,"fromByte":12,"byteLen":20,"optionV":"VIA test.","start":"192.168.1.2","end_ip":"192.168.1.100","subnet":"192.168.0.0","mask":"255.255.0.0","lease":3000,"eth":0},"eth2":[{"option":1,"className":\"TT\","idType":1,"valueType":1,"fromByte":12,"byteLen":20,"optionV":"VIA","start":"192.168.3.2","end_ip":"192.168.3.100","subnet":"192.168.3.0","mask":"255.255.255.0"},{"option":0,"start":"192.168.2.2","end_ip":"192.168.2.100","subnet":"192.168.2.0","mask":"255.255.255.0"}]}'
	--bRelay=luci.http.formvalue('dhcp_relay')
			
	request=luci.http.formvalue('data')
	if(request) then
		info_list =json.decode(request)
		bRelay=info_list.relay
		if(info_list.dhcp6) then
			SetDhcp6Config()
		else	
			SetACDhcpdConfig()
		end	
		if(bRelay==1) then
			setRelayInfo(1)
		else
			setRelayInfo(0)		
		end	
		luci.http.prepare_content("application/json")
		luci.http.write_json('OK')
		return
	end	
end
function setRelayInfo(ebl)
	if(ebl==1) then
		os.execute('uci set dhcrelay.ipv4.disabled=0')
		os.execute('uci delete dhcrelay.ipv4.dhcpserver')
		os.execute('uci delete dhcrelay.ipv4.listen_if')
		os.execute('uci commit')
	else
		os.execute('uci set dhcrelay.ipv4.disabled=1')
		os.execute('uci commit')
	end	
	
	if(ebl==1) then
		local eth0_relay=info_list.relay1
		local eth1_relay=info_list.relay2
		local eth2_relay=info_list.relay3
		local eth3_relay=info_list.relay4
		if(eth0_relay ~=nil and eth0_relay~='') then
			os.execute('uci add_list dhcrelay.ipv4.dhcpserver="' .. eth0_relay ..'"')
			os.execute('uci add_list dhcrelay.ipv4.listen_if=eth0')
		end	
		if(eth1_relay ~=nil and eth1_relay~='') then
			os.execute('uci add_list dhcrelay.ipv4.dhcpserver="' .. eth1_relay ..'"')
			os.execute('uci add_list dhcrelay.ipv4.listen_if=eth1')
		end	
		if(eth2_relay ~=nil and eth2_relay~='') then
			os.execute('uci add_list dhcrelay.ipv4.dhcpserver="' .. eth2_relay ..'"')
			os.execute('uci add_list dhcrelay.ipv4.listen_if=eth2')
		end	
		if(eth3_relay ~=nil and eth3_relay~='') then
			os.execute('uci add_list dhcrelay.ipv4.dhcpserver="' .. eth3_relay ..'"')
			os.execute('uci add_list dhcrelay.ipv4.listen_if=eth3')
		end	
		os.execute('uci commit')
		os.execute('/etc/init.d/dhcrelay4 restart')
		os.execute('/etc/init.d/dhcrelay4 enable')
	else
		os.execute('/etc/init.d/dhcrelay4 stop')
		os.execute('/etc/init.d/dhcrelay4 disable')
	end	
end
function SetDhcp6Config()
	local buf=''
	local buf_radvd=''
	local line=''
	fd=io.open('/etc/dhcp/dhcpd6.conf','wb')
	if(fd == nil) then
		luci.http.status(500,'open file failed')
	end
	buf = "# Sample configuration file for ISC dhcpd6 for Debian\n\n" ..
		  "#\n" ..
		  "#\n" ..
		  "#new define option\n" ..
		  "# \n" ..
		  "log-facility local7;\n";
	buf_radvd="interface eth0\n" ..
			  "{\n" ..
			  "AdvSendAdvert on;\n" ..
			  "AdvManagedFlag on;\n" ..
			  "AdvOtherConfigFlag on;\n" ..
			  "AdvLinkMTU 1480;\n";
	local function setDhcpEther()
		local ethid=eth_cur.eth			
			if(eth_cur.subnet and eth_cur.mask) then
				line =string.format('subnet6 %s/%d {\n',eth_cur.subnet,eth_cur.mask)
				buf =buf .. line
				line=string.format('prefix %s/%d {\n',eth_cur.subnet,eth_cur.mask)
				buf_radvd =buf_radvd .. line
				buf_radvd=buf_radvd .. "AdvOnLink on;\nAdvRouterAddr on;\n};\n"
			end
			if(ethid == 0) then
				buf =buf .. ' INTERFACE eth0;\n'
			elseif(ethid == 1) then
				buf =buf .. ' INTERFACE eth1;\n'
			elseif(ethid == 2) then
				buf =buf .. ' INTERFACE eth2;\n'
			elseif(ethid == 3) then
				buf =buf .. ' INTERFACE eth3;\n'
			end			
						
			local ip_start=eth_cur.start
			local ip_end =eth_cur.end_ip	
			if(ip_start and ip_end) then
				buf =buf .. ' range6 ' .. ip_start .. ' ' .. ip_end .. ';\n'
			end
			local primaryDNS=eth_cur.primaryDNS
			local secondDNS =eth_cur.secondDNS
			if(primaryDNS ~=nil) then
				buf = buf ..' option domain-name-servers ' .. primaryDNS
				if(secondDNS ~=nil) then
					buf = buf .. ',' .. secondDNS .. ';\n'
				else
					buf = buf ..';\n'
				end
			elseif(secondDNS ~=nil) then
					buf = buf .. ' option domain-name-servers ' .. secondDNS .. ';\n'
			end
			
			local domain=eth_cur.domain
			if(domain ~=nil) then
				buf = buf .. ' option domain-name "' .. domain .. '";\n'
			end
			
			local gateway=eth_cur.gateway
			if(gateway ~=nil) then
				buf = buf .. ' option routers ' .. gateway .. ';\n'
			end
			
			local lease=eth_cur.lease
			if(lease ~=nil) then
				buf = buf .. ' default-lease-time ' .. lease .. ';\n'
			end
			buf = buf .. ' max-lease-time 30000;\n';	
			buf =buf .. '}\n'
	end
	local function eachEtheSet(eth)
		local cnt=0
		local eth_tmp=eth	    

		if(eth_tmp)   then
			eth_cnt=#(eth_tmp)
			eth_cur=eth_tmp
			
			if(eth_cnt>0) then
				cnt =1
				while(cnt<=eth_cnt) do
					eth_cur=eth_tmp[cnt]
					setDhcpEther()
					cnt =cnt+1
				end
				
			else
				setDhcpEther()
			end	
		end
	end	
	
		eachEtheSet(info_list.eth1)
		eachEtheSet(info_list.eth2)
		eachEtheSet(info_list.eth3)
		eachEtheSet(info_list.eth4)	
		
		ret=fd:write(buf)	
		if(ret==nil) then
			print('save failed')
		end
		io.close(fd)
		
		fd=io.open('/etc/radvd.conf','wb')
		if(fd == nil) then
			luci.http.status(500,'open file failed')
		end
		buf_radvd=buf_radvd .. "};\n "
		ret=fd:write(buf_radvd)	
		if(ret==nil) then
			return -1
		end
		io.close(fd) 
		if(info_list.dhcp6==1) then
			os.execute('/etc/init.d/dhcpd6 restart')
			os.execute('/etc/init.d/dhcpd6 enable')
			os.execute('/etc/init.d/radvd start')
			os.execute('/etc/init.d/radvd enable')
		else
			os.execute('/etc/init.d/dhcpd6 stop')
			os.execute('/etc/init.d/dhcpd6 disable')
			os.execute('/etc/init.d/radvd stop')
			os.execute('/etc/init.d/radvd disable')
		end
end
function SetACDhcpdConfig()
	local buf=''
	local line=''
	fd=io.open('/etc/dhcp/dhcpd.conf','wb')
	if(fd == nil) then
		luci.http.status(500,'open file failed')
	end
	buf = "# Sample configuration file for ISC dhcpd for Debian\n\n" ..
		  "# The ddns-updates-style parameter controls whether or not the server will\n" ..
		  "# attempt to do a DNS update when a lease is confirmed. We default to the\n" ..
		  "# behavior of the version 2 packages ('none', since DHCP v2 didn't\n" ..
		  "# have support for DDNS.)\n" ..
		  "ddns-update-style none;\n";
	local function setDhcpEther()
		local ethid=eth_cur.eth
			if(eth_cur.option ==1 ) then   --option enable
				line='class "' .. eth_cur.className ..'"{\n'
				buf= buf .. line
				local idType=eth_cur.idType
				local valueType=eth_cur.valueType
				if(idType == 1) then
					if(valueType == 1) then
						line='match if substring(option agent.circuit-id,' .. eth_cur.fromByte .. ',' .. eth_cur.byteLen .. ') = "' .. eth_cur.optionV .. '";\n'
						buf= buf .. line
					elseif(valueType ==2) then
						line =string.format('match if substring(option agent.circuit-id,%d,%d) = %s;\n',eth_cur.fromByte,eth_cur.byteLen,eth_cur.optionV)
						buf= buf .. line
					elseif(valueType ==3) then
						line =string.format('match if binary-to-ascii(10,16,"",substring(option agent.circuit-id,%d,%d)) = "%s";\n',eth_cur.fromByte,eth_cur.byteLen,eth_cur.optionV)
						buf= buf .. line
					end	
				elseif(idType == 2) then
					if(valueType == 1) then
						line='match if substring(option agent.remote-id,' .. eth_cur.fromByte .. ',' .. eth_cur.byteLen .. ',"' .. eth_cur.optionV .. '";\n'
						buf= buf .. line
					elseif(valueType ==2) then
						line =string.format('match if substring(option agent.remote-id,%d,%d) = %s;\n',eth_cur.fromByte,eth_cur.byteLen,eth_cur.optionV)
						buf= buf .. line
					elseif(valueType ==3) then
						line =string.format('match if binary-to-ascii(10,16,"",substring(option agent.remote-id,%d,%d)) = "%s";\n',eth_cur.fromByte,eth_cur.byteLen,eth_cur.optionV)
						buf= buf .. line
					end	
				end
				buf = buf .. '}\n'		
			end	
			if(eth_cur.subnet and eth_cur.mask) then
				line =string.format('subnet %s netmask %s {\n',eth_cur.subnet,eth_cur.mask)
				buf =buf .. line
			end
			if(ethid == 0) then
				buf =buf .. ' INTERFACE eth0;\n'
			elseif(ethid == 1) then
				buf =buf .. ' INTERFACE eth1;\n'
			elseif(ethid == 2) then
				buf =buf .. ' INTERFACE eth2;\n'
			elseif(ethid == 3) then
				buf =buf .. ' INTERFACE eth3;\n'
			end	
			
			if(eth_cur.option ==1 ) then
				buf = buf .. 'pool{\n'
				line=string.format('allow members of "%s";\n',eth_cur.className)
				buf = buf .. line
			end
			
			local ip_start=eth_cur.start
			local ip_end =eth_cur.end_ip	
			if(ip_start and ip_end) then
				buf =buf .. ' range ' .. ip_start .. ' ' .. ip_end .. ';\n'
			end
			local primaryDNS=eth_cur.primaryDNS
			local secondDNS =eth_cur.secondDNS
			if(primaryDNS ~=nil) then
				buf = buf ..' option domain-name-servers ' .. primaryDNS
				if(secondDNS ~=nil) then
					buf = buf .. ',' .. secondDNS .. ';\n'
				else
					buf = buf ..';\n'
				end
			elseif(secondDNS ~=nil) then
					buf = buf .. ' option domain-name-servers ' .. secondDNS .. ';\n'
			end
			
			local domain=eth_cur.domain
			if(domain ~=nil) then
				buf = buf .. ' option domain-name "' .. domain .. '";\n'
			end
			
			local gateway=eth_cur.gateway
			if(gateway ~=nil) then
				buf = buf .. ' option routers ' .. gateway .. ';\n'
			end
			
			local lease=eth_cur.lease
			if(lease ~=nil) then
				buf = buf .. ' default-lease-time ' .. lease .. ';\n'
			end
			buf = buf .. ' max-lease-time 30000;\n';
			
			if(eth_cur.option ==1 ) then
				buf =buf .. '}\n'
			end
				buf =buf .. '}\n'
	end
	local function eachEtheSet(eth)
		local cnt=0
		local eth_tmp=eth	    

		if(eth_tmp)   then
			eth_cnt=#(eth_tmp)
			eth_cur=eth_tmp
			
			if(eth_cnt>0) then
				cnt =1
				while(cnt<=eth_cnt) do
					eth_cur=eth_tmp[cnt]
					setDhcpEther()
					cnt =cnt+1
				end
				
			else
				setDhcpEther()
			end	
		end
	end	
	
		eachEtheSet(info_list.eth1)
		eachEtheSet(info_list.eth2)
		eachEtheSet(info_list.eth3)
		eachEtheSet(info_list.eth4)	
		
		write_bytes=#buf
		ret=fd:write(buf)	
		if(ret==nil) then
			print('save failed')
		end
		io.close(fd)
		if(info_list.dhcp==1) then
			os.execute('/etc/init.d/dhcpd restart')
			os.execute('/etc/init.d/dhcpd enable')
		else
			os.execute('/etc/init.d/dhcpd stop')
			os.execute('/etc/init.d/dhcpd disable')
		end
end
