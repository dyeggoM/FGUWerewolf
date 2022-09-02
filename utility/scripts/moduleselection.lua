-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

RECORD_DEFAULT_HEIGHT = 100;
LIST_RIGHT_OFFSET = 40;
LIST_BOTTOM_OFFSET = 140;

local _nLoadedFilter = 0;
local _nSharedFilter = 0;
local _nRulesetFilter = 0;
local _sNameFilterLower = "";
local _sAuthorFilterLower = "";

local _tFilteredModules = {};

local _nPageSize = 10;

--
--	EVENTS
--

function onInit()
	ListManager.initCustomList(self);

	if Session.IsHost then
		filter_shared.setVisible(true);
	end

	ListManager.refreshDisplayList(self);
	
	self.onSizeChanged = handleSizeChanged;
end
function onClose()
	ListManager.onCloseWindow(self);
end

function handleSizeChanged()
	local nWinWidth, nWinHeight = getSize();
	local nListLeft, nListTop = list.getPosition();
	local w = nWinWidth - nListLeft - LIST_RIGHT_OFFSET;
	local h = nWinHeight - nListTop - LIST_BOTTOM_OFFSET;

	local nColWidth = list.getColumnWidth();
	local nRecordsWide = 1;
	if nColWidth > 0 then
		nRecordsWide = math.max(math.floor(w / nColWidth), 1)
	end
	local nRecordsHigh = math.max(math.floor(h / RECORD_DEFAULT_HEIGHT), 1);

	local nNewPageSize = math.max(nRecordsWide * nRecordsHigh, 1);
	if _nPageSize ~= nNewPageSize then
		_nPageSize = nNewPageSize;
		ListManager.refreshDisplayList(self);
	end
end

function onModuleAdded(sModule)
	ListManager.refreshDisplayList(self);
end
function onModuleUpdated(sModule)
	local bHandled = false;
	for _,w in ipairs(list.getWindows()) do
		if w.getModuleName() == sModule then
			local tInfo = ModuleManager.getModuleInfo(sModule);
			if isFilteredRecord(tInfo) then
				w.update(tInfo);
				bHandled = true;
			end
			break;
		end
	end
	if not bHandled then
		ListManager.refreshDisplayList(self);
	end
end
function onModuleRemoved(sModule)
	ListManager.refreshDisplayList(self);
end

function onNameFilterChanged()
	local sNewFilterLower = filter_name.getValue():lower();
	if _sNameFilterLower ~= sNewFilterLower then
		_sNameFilterLower = sNewFilterLower;
		ListManager.setDisplayOffset(self, 0);
	end
end
function onAuthorFilterChanged()
	local sNewFilterLower = filter_author.getValue():lower();
	if _sAuthorFilterLower ~= sNewFilterLower then
		_sAuthorFilterLower = sNewFilterLower;
		ListManager.setDisplayOffset(self, 0);
	end
end
function onLoadedFilterChanged()
	local nNewFilter = filter_loaded.getValue();
	if _nLoadedFilter ~= nNewFilter then
		_nLoadedFilter = nNewFilter;
		ListManager.setDisplayOffset(self, 0);
	end
end
function onSharedFilterChanged()
	local nNewFilter = filter_shared.getValue();
	if _nSharedFilter ~= nNewFilter then
		_nSharedFilter = nNewFilter;
		ListManager.setDisplayOffset(self, 0);
	end
end
function onRulesetFilterChanged()
	local nNewFilter = filter_ruleset.getValue();
	if _nRulesetFilter ~= nNewFilter then
		_nRulesetFilter = nNewFilter;
		ListManager.setDisplayOffset(self, 0);
	end
end

--
--	BUTTON HANDLING
--

function setPermissions(sPermission)
	for sModule,_ in pairs(ModuleManager.getAllModuleInfo()) do
		setModulePermissions(sModule, sPermission);
	end
end
function setModulePermissions(sModule, sPermission)
	if sPermission == "disallow" then
		Module.setModulePermissions(sModule, false, false);
	elseif sPermission == "allow" then
		Module.setModulePermissions(sModule, true, false);
	end
end
function toggleActivation(sModule)
	local tInfo = ModuleManager.getModuleInfo(sModule);
	if tInfo.loaded then
		Module.deactivate(sModule);
	else
		Module.activate(sModule);
	end
end

--
--	LIST HANDLING
--

function addDisplayListItem(v)
	local wItem = list.createWindow();
	wItem.setData(v);
end

function getAllRecords()
	return ModuleManager.getAllModuleInfo();
end
function getPageSize()
	return _nPageSize;
end

function getSortFunction()
	return sortFunc;
end
function sortFunc(a, b)
	if a.displayname ~= b.displayname then
		return a.displayname < b.displayname;
	end
	return a.name < b.name;
end

function isFilteredRecord(v)
	if not Session.IsHost and (v.permission == "disallow") then
		return false;
	end
	if _nRulesetFilter == 1 then
		if v.anyflag then
			return false;
		end
	elseif _nRulesetFilter == 2 then
		if not v.anyflag then
			return false;
		end
	end
	if _nLoadedFilter == 1 then
		if not v.loaded then
			return false;
		end
	elseif _nLoadedFilter == 2 then
		if v.loaded then
			return false;
		end
	end
	if _nSharedFilter == 1 then
		if v.permission == "disallow" then
			return false;
		end
	elseif _nSharedFilter == 2 then
		if v.permission ~= "disallow" then
			return false;
		end
	end
	if _sNameFilterLower ~= "" then
		if not string.find(v.displayname:lower(), _sNameFilterLower, 0, true) then
			return false;
		end
	end
	if _sAuthorFilterLower ~= "" then
		if not string.find(v.author:lower(), _sAuthorFilterLower, 0, true) then
			return false;
		end
	end
	return true;
end
