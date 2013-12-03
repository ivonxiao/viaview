module("luci.controller.admin.wlan", package.seeall)

function index()
	local uci = require("luci.model.uci").cursor()
	local page


		local has_wifi = false

		uci:foreach("wireless", "wifi-device",
			function(s)
				has_wifi = true
				return false
			end)	
			
		if has_wifi then		
			
			page = entry({"admin", "wlan", "wireless_join"}, call("wifi_join"), nil)
			page.leaf = true

			page = entry({"admin", "wlan", "wireless_add"}, call("wifi_add"), nil)
			page.leaf = true

			page = entry({"admin", "wlan", "wireless_delete"}, call("wifi_delete"), nil)
			page.leaf = true

			page = entry({"admin", "wlan", "wireless_status"}, call("wifi_status"), nil)
			page.leaf = true
			
			page = entry({"admin", "wlan", "wireless_status_sole"}, cbi("admin_network/wifi"), nil)
			page.leaf = true
			
			page = entry({"admin", "wlan", "wireless_reconnect"}, call("wifi_reconnect"), nil)
			page.leaf = true

			page = entry({"admin", "wlan", "wireless_shutdown"}, call("wifi_shutdown"), nil)
			page.leaf = true				
			
			page = entry({"admin", "wlan"}, template("admin_network/wifi_overview"), _("WLAN"), 90)
			page.subindex = true
		end		
		
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
			--luci.http.redirect(luci.dispatcher.build_url("admin/network/wireless_join?device=" .. dev))
			luci.http.redirect(luci.dispatcher.build_url("admin/wlan/wireless_join?device=" .. dev))
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
			ssid       = "Public",
			encryption = "none",
			network    = "lan"
		})

		ntm:save("wireless")
		--luci.http.redirect(net:adminlink())
		luci.http.redirect(luci.dispatcher.build_url("admin/wlan/wireless_status_sole",net:id()))
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

	--luci.http.redirect(luci.dispatcher.build_url("admin/network/wireless"))
	luci.http.redirect(luci.dispatcher.build_url("admin/wlan"))
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
