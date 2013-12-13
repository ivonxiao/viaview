var util={};
util.match_ipv6_addr=function(str_ipv6) {
	var exp_ipv6=/^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/  
	return exp_ipv6.test(str_ipv6);
}
util.calc_ipv6_net_no=function(addr,mask) {
	var net=[0,0,0,0,0,0,0,0],
		ret=[],
		result;
	var i=0,
		l=0,
		arr_section,
		str_front='',
		str_behind='';
	var abbr=addr.indexOf('::');
	if(abbr!==-1) { // 8 hex groups
		str_front=addr.slice(0,abbr);
		arr_section=str_front.split(':');
		for(i=0,l=arr_section.length;i<l;i++)
			net[i]=arr_section[i];
		str_behind=addr.slice(abbr+2);
		arr_section=str_behind.split(':');
		for(i=0,l=arr_section.length;i<l;i++)
			net[8-l+i]=arr_section[i];
		//console.log(net);	
	}
	else {
		arr_section=addr.split(':');
		for(i=0,l=arr_section.length;i<l;i++)
			net[i]=arr_section[i];
	}
	l=mask;
	for(i=0;i<8;i++) {
		if(l>16) {
			ret[i]=(parseInt(net[i],16)&0xffff).toString(16);
			l=l-16;
		}else {
			ret[i]=(parseInt(net[i],16)&((Math.pow(2,l)-1))<<(16-l)).toString(16);
			break;
		}		
	}
	if(ret.length==8) result=ret.join(':');
	else result=ret.join(':')+'::';
	//console.log(result);
	return result;			
}		
if (!window.JSON) {
  window.JSON = {
    parse: function (sJSON) { return eval("(" + sJSON + ")"); },
    stringify: function (vContent) {
      if (vContent instanceof Object) {
        var sOutput = "";
        if (vContent.constructor === Array) {
          for (var nId = 0; nId < vContent.length; sOutput += this.stringify(vContent[nId]) + ",", nId++);
          return "[" + sOutput.substr(0, sOutput.length - 1) + "]";
        }
        if (vContent.toString !== Object.prototype.toString) { return "\"" + vContent.toString().replace(/"/g, "\\$&") + "\""; }
        for (var sProp in vContent) { sOutput += "\"" + sProp.replace(/"/g, "\\$&") + "\":" + this.stringify(vContent[sProp]) + ","; }
        return "{" + sOutput.substr(0, sOutput.length - 1) + "}";
      }
      return typeof vContent === "string" ? "\"" + vContent.replace(/"/g, "\\$&") + "\"" : String(vContent);
    }
  };
}
util.uniqueSel=function(sel,unsel,sel_section,unsel_section) {
	if(sel.checked) {
		unsel.checked=false;
		unsel_section.style.display='none';
		sel_section.style.display='block';
	}		
}
util.$id=function(sid) {
	return document.getElementById(sid);
}
