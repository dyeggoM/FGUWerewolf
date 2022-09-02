-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _tModules = nil;
local _fCallback = nil;
local _vCustomData = nil;

function initialize(vModule, fCallback, aCustom)
	if type(vModule) == "table" then
		_tModules = vModule;
	else
		_tModules = { vModule };
	end
	_fCallback = fCallback;
	_vCustomData = aCustom;
	
	activateNextModuleLoad();
end

function activateNextModuleLoad()
	while #_tModules > 0 and _tModules[1] == "*" do
		table.remove(_tModules, 1);
	end
	
	if #_tModules > 0 then
		local sModuleName = nil;
		local tInfo = ModuleManager.getModuleInfo(_tModules[1]);
		if tInfo then
			sModuleName = tInfo.displayname;
		end
		local sMessage = string.format(Interface.getString("module_message_missinglink"), sModuleName or _tModules[1]);
		message.setValue(sMessage);
	else
		if _fCallback then
			_fCallback(_vCustomData);
		end
		close();
	end
end

function processOK()
	if #_tModules > 0 then
		Module.activate(_tModules[1]);
		if not ModuleManager.isModuleLoaded(_tModules[1]) then
			ChatManager.SystemMessage(string.format("%s (%s)", Interface.getString("module_message_failedload"), _tModules[1]));
			processCancel();
			return;
		end
		table.remove(_tModules, 1);
	end
	activateNextModuleLoad();
end

function processCancel()
	close();
end
