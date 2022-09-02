-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function isClientFGU()
	Debug.console("UtilityManager.isClientFGU - DEPRECATED - 2022-07-12 - No longer supported, assume FGU only");
	ChatManager.SystemMessage("UtilityManager.isClientFGU - DEPRECATED - 2022-07-12 - Contact forge/extension author");
	return true;
end

-- NOTE: Converts table into numerically indexed table, based on sort order of original keys. Original keys are not included in new table.
function getSortedTable(aOriginal)
	local aSorter = {};
	for k,_ in pairs(aOriginal) do
		table.insert(aSorter, k);
	end
	table.sort(aSorter);
	
	local aSorted = {};
	for _,v in ipairs(aSorter) do
		table.insert(aSorted, aOriginal[v]);
	end
	return aSorted;
end

-- NOTE: Performs a structure deep copy. Does not copy meta table information.
function copyDeep(v)
	if type(v) == "table" then
		local v2 = {};
		for kTable, vTable in next, v, nil do
			v2[copyDeep(kTable)] = copyDeep(vTable);
		end
		return v2;
	end
	
	return v;
end

function encodeXML(s)
	if not s then
		return "";
	end
	return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"):gsub("'", "&apos;");
end

--
--	Database helper functions
--

function parseDataBaseNodePath(vNode)
	local sPath = "";
	if type(vNode) == "databasenode" then
		sPath = vNode.getPath();
	elseif type(vNode) == "string" then
		sPath = vNode;
	end

	local sModule = nil;
	local tPath = {};

	local tModuleSplit = StringManager.splitByPattern(sPath, "@");
	if #tModuleSplit > 0 then
		if #tModuleSplit > 1 then
			sModule = table.concat(tModuleSplit, "@", 2);
		end

		tPath = StringManager.splitByPattern(tModuleSplit[1], "%.");
	end

	return tPath, sModule or "";
end

function isDataBaseNodePathMatch(v1, v2, bCompareModule)
	local tPath1, sModule1 = UtilityManager.parseDataBaseNodePath(v1);
	local tPath2, sModule2 = UtilityManager.parseDataBaseNodePath(v2);

	if bCompareModule then
		if sModule1 ~= sModule2 then
			return false;
		end
	end

	if #tPath1 ~= #tPath2 then
		return false;
	end

	for k,v in ipairs(tPath1) do
		if (v ~= "*") and (tPath2[k] ~= "*") then
			if (v ~= tPath2[k]) then
				return false;
			end
		end
	end

	return true;
end

function getDataBaseNodePathSplit(vNode)
	local tPath = UtilityManager.parseDataBaseNodePath(vNode);
	if #tPath == 0 then
		return "";
	end
	return unpack(tPath);
end

function getNodeAccessLevel(vNode)
	if vNode then
		if vNode.isPublic() then
			return 2;
		else
			if Session.IsHost then
				local sOwner = vNode.getOwner();
				local aHolderNames = {};
				local aHolders = vNode.getHolders();
				for _,sHolder in pairs(aHolders) do
					if sOwner then
						if sOwner ~= sHolder then
							table.insert(aHolderNames, sHolder);
						end
					else
						table.insert(aHolderNames, sHolder);
					end
				end
				
				if #aHolderNames > 0 then
					return 1, aHolderNames;
				end
			end
		end
	end
	return 0;
end

function getNodeCategory(vNode)
	local vCategory = vNode.getCategory();
	if type(vCategory) == "table" then
		return vCategory.name;
	end
	return vCategory;
end

function getNodeModule(vNode)
	return vNode.getModule() or "";
end

function getRootNodeName(vNode)
	local nodeResult = nil;
	if type(vNode) == "databasenode" then
		nodeTemp = vNode;
	elseif type(vNode) == "string" then
		nodeTemp = DB.findNode(vNode);
	end
	while nodeTemp do
		nodeResult = nodeTemp;
		nodeTemp = nodeTemp.getParent();
	end
	if nodeResult then 
		return nodeResult.getName(); 
	end
	return "";
end

--
--	Window/control helper functions
--

function getWindowDatabasePath(w)
	if not w then
		return "";
	end

	local node = w.getDatabaseNode();
	if not node then
		return "";
	end

	return node.getPath();
end

function getTopWindow(w)
	local wTop = w;
	while wTop and (wTop.windowlist or wTop.parentcontrol) do
		if wTop.windowlist then
			wTop = wTop.windowlist.window;
		else
			wTop = wTop.parentcontrol.window;
		end
	end
	return wTop;
end

function setStackedWindowVisibility(w, bShow)
	local wTop = w;
	while wTop and (wTop.windowlist or wTop.parentcontrol) do
		if wTop.windowlist then
			wTop.windowlist.setVisible(bShow);
			wTop = wTop.windowlist.window;
		else
			wTop.parentcontrol.setVisible(bShow);
			wTop = wTop.parentcontrol.window;
		end
	end
end

function callStackedWindowFunction(w, sFunction, ...)
	local wTop = w;
	while wTop and (wTop.windowlist or wTop.parentcontrol) do
		if wTop[sFunction] then
			wTop[sFunction](...);
		end
		if wTop.windowlist then
			wTop = wTop.windowlist.window;
		else
			wTop = wTop.parentcontrol.window;
		end
	end
end

--
--  Callback helper functions
--

function registerCallback(t, fn)
	if not fn then
		return;
	end
	for _,v in ipairs(t) do
		if v == fn then
			return;
		end
	end
	table.insert(t, fn);
end
function unregisterCallback(t, fn)
	if not fn then
		return;
	end
	for k,v in ipairs(t) do
		if v == fn then
			table.remove(t, k);
			return;
		end
	end
end
function performCallbacks(t, ...)
	for _,fn in ipairs(t) do
		if fn(...) then
			return true;
		end
	end
	return false;
end
function performAllCallbacks(t, ...)
	for _,fn in ipairs(t) do
		fn(...);
	end
end

function registerKeyCallback(t, sKey, fn)
	if not t[sKey] then
		t[sKey] = {};
	end
	UtilityManager.registerCallback(t[sKey], fn);
end
function unregisterKeyCallback(t, sKey, fn)
	if t[sKey] then
		UtilityManager.unregisterCallback(t[sKey], fn);
		if #(t[sKey]) == 0 then
			t[sKey] = nil;
		end
	end
end
function performKeyCallbacks(t, sKey, ...)
	if t[sKey] then
		return UtilityManager.performCallbacks(t[sKey], ...);
	end
	return false;
end
function performAllKeyCallbacks(t, sKey, ...)
	if t[sKey] then
		UtilityManager.performAllCallbacks(t[sKey], ...);
	end	
end

function setKeySingleCallback(t, sKey, fn)
	t[sKey] = fn;
end
function getKeySingleCallback(t, sKey)
	return t[sKey];
end
function hasKeySingleCallback(t, sKey)
	return (t[sKey] ~= nil);
end
function performKeySingleCallback(t, sKey, ...)
	local fn = t[sKey];
	if fn then
		return fn(...);
	end
	return nil;
end

--
--	OOB Helpers
--

function encodeRollToOOB(rRoll)
	local msgOOB = UtilityManager.copyDeep(rRoll);

	local tEncodeBoolean = {};
	for k,v in pairs(rRoll) do
		if (type(v) == "boolean") and k:match("b[A-Z]") then
			if v then
				msgOOB[k] = 1;
			else
				msgOOB[k] = 0;
			end
		end
	end

	return msgOOB;
end

function decodeRollFromOOB(msgOOB)
	local rRoll = UtilityManager.copyDeep(msgOOB);

	local tDecodeNumber = {};
	local tDecodeBoolean = {};
	for k,v in pairs(msgOOB) do
		if k:match("n[A-Z]") then
			rRoll[k] = tonumber(rRoll[k]) or nil;
		elseif k:match("b[A-Z]") then
			rRoll[k] = ((tonumber(rRoll[k]) or 0) == 1);
		end
	end

	return rRoll;
end
