-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sInternalRecordType = "effect";

local _tRecords = {};

local bDelayedChildrenChanged = false;
local bDelayedRebuild = false;

local sFilter = "";

function onInit()
	ListManager.initCustomList(self);

	rebuildList();
	addHandlers();

	Module.onModuleLoad = onModuleLoadAndUnload;
	Module.onModuleUnload = onModuleLoadAndUnload;
end
function onClose()
	ListManager.onCloseWindow(self);
	
	removeHandlers();
end

function onSortCompare(w1, w2)
	return not ListManager.defaultSortFunc(_tRecords[w1.getDatabaseNode()], _tRecords[w2.getDatabaseNode()]);
end

function onModuleLoadAndUnload(sModule)
	local nodeRoot = DB.getRoot(sModule);
	if nodeRoot then
		local vNodes = LibraryData.getMappings(sInternalRecordType);
		for i = 1, #vNodes do
			if nodeRoot.getChild(vNodes[i]) then
				bDelayedRebuild = true;
				onListRecordsChanged(true);
				break;
			end
		end
	end
end
function addHandlers()
	function addHandlerHelper(vNode)
		local sPath = DB.getPath(vNode);
		local sChildPath = sPath .. ".*@*";
		DB.addHandler(sChildPath, "onAdd", onChildAdded);
		DB.addHandler(sChildPath, "onDelete", onChildDeleted);
		DB.addHandler(DB.getPath(sChildPath, "label"), "onUpdate", onChildNameChange);
		DB.addHandler(DB.getPath(sChildPath, "isgmonly"), "onUpdate", onChildGMOnlyChange);
	end
	
	local vNodes = LibraryData.getMappings(sInternalRecordType);
	for i = 1, #vNodes do
		addHandlerHelper(vNodes[i]);
	end
end
function removeHandlers()
	function removeHandlerHelper(vNode)
		local sPath = DB.getPath(vNode);
		local sChildPath = sPath .. ".*@*";
		DB.removeHandler(sChildPath, "onAdd", onChildAdded);
		DB.removeHandler(sChildPath, "onDelete", onChildDeleted);
		DB.removeHandler(DB.getPath(sChildPath, "label"), "onUpdate", onChildNameChange);
		DB.removeHandler(DB.getPath(sChildPath, "isgmonly"), "onUpdate", onChildGMOnlyChange);
	end
	
	local vNodes = LibraryData.getMappings(sInternalRecordType);
	for i = 1, #vNodes do
		removeHandlerHelper(vNodes[i]);
	end
end

function onChildAdded(vNode)
	addListRecord(vNode);
	onListRecordsChanged(true);
end
function onChildDeleted(vNode)
	if _tRecords[vNode] then
		_tRecords[vNode] = nil;
		onListRecordsChanged(true);
	end
end
function onListChanged()
	if bDelayedChildrenChanged then
		onListRecordsChanged(false);
	else
		list.update();
	end
end
function addListRecord(vNode)
	local rRecord = {};
	rRecord.vNode = vNode;
	rRecord.sDisplayName = DB.getValue(vNode, "label", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
	rRecord.nGMOnly = DB.getValue(vNode, "isgmonly", 0);

	_tRecords[vNode] = rRecord;
end
function onListRecordsChanged(bAllowDelay)
	if bAllowDelay then
		ListManager.helperSaveScrollPosition(self);
		bDelayedChildrenChanged = true;
		list.setDatabaseNode(nil);
	else
		bDelayedChildrenChanged = false;
		if bDelayedRebuild then
			bDelayedRebuild = false;
			rebuildList(true);
		end
		ListManager.refreshDisplayList(self);
	end
end
function rebuildList(bSkipRefresh)
	_tRecords = {};
	RecordManager.callForEachRecord(sInternalRecordType, addListRecord);

	ListManager.setDisplayOffset(self, 0, true);
	if not bSkipRefresh then
		onListRecordsChanged();
	end
end

function onFilterChanged()
	sFilter = filter.getValue():lower();
	ListManager.refreshDisplayList(self, true);
end
function onChildNameChange(vNameNode)
	local vNode = vNameNode.getParent();
	local rRecord = _tRecords[vNode];
	rRecord.sDisplayName = DB.getValue(vNode, "label", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
	ListManager.refreshDisplayList(self);
end
function onChildGMOnlyChange(vNameNode)
	local vNode = vNameNode.getParent();
	local rRecord = _tRecords[vNode];
	rRecord.nGMOnly = DB.getValue(vNode, "isgmonly", 0);
	ListManager.refreshDisplayList(self);
end

function getAllRecords()
	return _tRecords;
end

function isFilteredRecord(v)
	if sFilter ~= "" then
		if not string.find(v.sDisplayNameLower, sFilter, 0, true) then
			return false;
		end
	end
	if v.nGMOnly == 1 and not Session.IsHost then
		return false;
	end
	return true;
end
