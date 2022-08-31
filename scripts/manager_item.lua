-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_TRANSFERITEM = "transferitem";
OOB_MSGTYPE_TRANSFERCURRENCY = "transfercurrency";
OOB_MSGTYPE_TRANSFERPARCEL = "transferparcel";
OOB_MSGTYPE_TRANSFERITEMSTRING = "transferitemstring";

local aDeleteCopyFields = { "count", "locked", "location", "carried", "showonminisheet", "assign" };

--
-- INITIALIZATION
--

function onInit()
	ItemManager.addStandardItemTransferHandlers();
end
function addStandardItemTransferHandlers()
	OOBManager.registerOOBMsgHandler(ItemManager.OOB_MSGTYPE_TRANSFERITEM, ItemManager.handleItemTransfer);
	OOBManager.registerOOBMsgHandler(ItemManager.OOB_MSGTYPE_TRANSFERCURRENCY, ItemManager.handleCurrencyTransfer);
	OOBManager.registerOOBMsgHandler(ItemManager.OOB_MSGTYPE_TRANSFERPARCEL, ItemManager.handleParcelTransfer);
	OOBManager.registerOOBMsgHandler(ItemManager.OOB_MSGTYPE_TRANSFERITEMSTRING, ItemManager.handleItemStringTransfer);
end

--
-- SETTINGS
--

local _tDefaultInventoryPaths = { "inventorylist" };
local _tCustomInventoryPaths = {};
function setInventoryPaths(sRecordType, tPaths)
	_tCustomInventoryPaths[sRecordType] = tPaths;
end
function getInventoryPaths(sRecordType)
	return _tCustomInventoryPaths[sRecordType] or _tDefaultInventoryPaths;
end

local _tDefaultEncumbranceFields = { "carried", "count", "weight" };
local _tCustomEncumbranceFields = {};
function setEncumbranceFields(sRecordType, tFields)
	_tCustomEncumbranceFields[sRecordType] = tFields;
end
function getEncumbranceFields(sRecordType)
	return _tCustomEncumbranceFields[sRecordType] or _tDefaultEncumbranceFields;
end

-- NOTE: Assumes field is a child of each item record, and is a string data type.
local _sDefaultCostField = "cost";
local _sCustomCostField = nil;
function setCostField(sField)
	_sCustomCostField = sField;
end
function getCostField()
	return _sCustomCostField or _sDefaultCostField;
end

--
-- HANDLERS
--

local fCustomCharAdd = nil;
function setCustomCharAdd(fCharAdd)
	fCustomCharAdd = fCharAdd;
end
function onCharAddEvent(nodeItem)
	if fCustomCharAdd then
		fCustomCharAdd(nodeItem);
	end
end

local fCustomCharRemove = nil;
function setCustomCharRemove(fCharRemove)
	fCustomCharRemove = fCharRemove;
end
function onCharRemoveEvent(nodeItem)
	if fCustomCharRemove then
		fCustomCharRemove(nodeItem);
	end
end
function addFieldToIgnore (sIgnore)
	if type(sIgnore) == "string" and sIgnore ~= "" then
		table.insert(aDeleteCopyFields, sIgnore);
	end
end

function addTransferNotificationHandler(fn)
	Debug.console("ItemManager.addTransferNotificationHandler - DEPRECATED - 2022-07-12 - Use registerPreTransferHandler");
	ChatManager.SystemMessage("ItemManager.addTransferNotificationHandler - DEPRECATED - 2022-07-12 - Contact forge/extension author");
end

local _sPackIncludedItemListPath = "subitems";
function setPackIncludedItemListPath(s)
	_sPackIncludedItemListPath = s;
end
function getPackIncludedItemListPath(s)
	return _sPackIncludedItemListPath;
end

local _tPreTransferHandler = {};
function registerPreTransferHandler(fn)
	UtilityManager.registerCallback(_tPreTransferHandler, fn);
end
function unregisterPreTransferHandler(fn)
	UtilityManager.unregisterCallback(_tPreTransferHandler, fn);
end
function callPreTransferHandlers(...)
	return UtilityManager.performCallbacks(_tPreTransferHandler, ...);
end

local _tCleanupTransferHandler = {};
function registerCleanupTransferHandler(fn)
	UtilityManager.registerCallback(_tCleanupTransferHandler, fn);
end
function unregisterCleanupTransferHandler(fn)
	UtilityManager.unregisterCallback(_tCleanupTransferHandler, fn);
end
function callCleanupTransferHandlers(...)
	return UtilityManager.performCallbacks(_tCleanupTransferHandler, ...);
end

local _tPostTransferHandler = {};
function registerPostTransferHandler(fn)
	UtilityManager.registerCallback(_tPostTransferHandler, fn);
end
function unregisterPostTransferHandler(fn)
	UtilityManager.unregisterCallback(_tPostTransferHandler, fn);
end
function callPostTransferHandlers(...)
	return UtilityManager.performCallbacks(_tPostTransferHandler, ...);
end

--
-- ACTIONS
--

function getIDState(nodeRecord, bIgnoreHost)
	if ItemManager2 and ItemManager2.getIDState then
		return ItemManager2.getIDState(nodeRecord, bIgnoreHost);
	end
	
	local bID = true;
	if (bIgnoreHost or not Session.IsHost) then
		bID = (DB.getValue(nodeRecord, "isidentified", 1) == 1);
	end
	
	return bID, true;
end

function getDisplayName(nodeItem, bIgnoreHost)
	local bID = ItemManager.getIDState(nodeItem, bIgnoreHost);
	if bID then
		return DB.getValue(nodeItem, "name", "");
	end
	
	local sName = DB.getValue(nodeItem, "nonid_name", "");
	if sName == "" then
		sName = Interface.getString("library_recordtype_empty_nonid_item");
	end
	return sName;
end

function getSortName(nodeItem)
	local sName = ItemManager.getDisplayName(nodeItem);
	return sName:lower();
end

function getItemSourceType(vNode)
	local sNodePath = nil;
	if type(vNode) == "databasenode" then
		sNodePath = vNode.getPath();
	elseif type(vNode) == "string" then
		sNodePath = vNode;
	end
	if not sNodePath then
		return "";
	end

	for _,vMapping in ipairs(LibraryData.getMappings("charsheet")) do
		if StringManager.startsWith(sNodePath, vMapping) then
			return "charsheet";
		end
	end

	for _,vMapping in ipairs(LibraryData.getMappings("item")) do
		if StringManager.startsWith(sNodePath, vMapping) then
			return "item";
		end
	end

	for _,vMapping in ipairs(LibraryData.getMappings("treasureparcel")) do
		if StringManager.startsWith(sNodePath, vMapping) then
			return "treasureparcel";
		end
	end

	if StringManager.startsWith(sNodePath, "partysheet") then
		return "partysheet";
	end

	if StringManager.startsWith(sNodePath, "temp") then
		return "temp";
	end

	return "";
end

function compareFields(node1, node2, bTop)
	if node1 == node2 then
		return false;
	end
	
	local tAllFields = {};
	local tChildren1 = node1.getChildren();
	local tChildren2 = node2.getChildren();
	for sName,_ in pairs(tChildren1) do
		if not bTop or not StringManager.contains(aDeleteCopyFields, sName) then
			tAllFields[sName] = true;
		end
	end
	for sName,_ in pairs(tChildren2) do
		if not bTop or not StringManager.contains(aDeleteCopyFields, sName) then
			tAllFields[sName] = true;
		end
	end

	for sName,_ in pairs(tAllFields) do
		local vChild1 = tChildren1[sName];
		local vChild2 = tChildren2[sName];

		if vChild1 and vChild2 then
			local sType = vChild1.getType();
			if sType ~= vChild2.getType() then
				return false;
			end

			if sType == "node" then
				if not ItemManager.compareFields(vChild1, vChild2, false) then
					return false;
				end
			elseif sType == "dice" then
				local diceChild1 = vChild1.getValue() or {};
				local diceChild2 = vChild2.getValue() or {};
				if #diceChild1 ~= #diceChild2 then
					return false;
				end
				table.sort(diceChild1, function(a,b) return a<b end);
				table.sort(diceChild2, function(a,b) return a<b end);
				for kDie,vDie in ipairs(diceChild1) do
					if (vDie ~= diceChild2[kDie]) then
						return false;
					end
				end
			else
				if vChild1.getValue() ~= vChild2.getValue() then
					return false;
				end
			end
		elseif vChild1 then
			local sType = vChild1.getType();
			local bMatch = (StringManager.contains({"number", "string", "formattedtext", "dice"}, sType) and vChild1.isEmpty());
			if not bMatch then
				return false;
			end
		elseif vChild2 then
			local sType = vChild2.getType();
			local bMatch = (StringManager.contains({"number", "string", "formattedtext", "dice"}, sType) and vChild2.isEmpty());
			if not bMatch then
				return false;
			end
		end
	end
	
	return true;
end

function isPack()
	return false;
end

--
-- HIGH-LEVEL ACTIONS
--

function addLinkToParcel(nodeParcel, sLinkClass, sLinkRecord, nCount)
	if sLinkClass == "treasureparcel" then
		for i = 1, (nCount or 1) do
			ItemManager.handleParcel(nodeParcel, sLinkRecord);
		end
	elseif LibraryData.isRecordDisplayClass("item", sLinkClass) then
		for i = 1, (nCount or 1) do
			ItemManager.handleItem(nodeParcel, nil, sLinkClass, sLinkRecord);
		end
	else
		return false;
	end
	
	return true;
end

function getAllInventoryListPaths(nodeTarget)
	local tAllListPaths = {};

	local sTargetRecordType = ItemManager.getItemSourceType(nodeTarget);
	if sTargetRecordType == "charsheet" then
		if ItemManager2 and ItemManager2.getCharItemListPaths then
			tAllListPaths = ItemManager2.getCharItemListPaths(nodeTarget);
		else
			table.insert(tAllListPaths, "inventorylist");
		end
	elseif sTargetRecordType == "treasureparcel" then
		table.insert(tAllListPaths, "itemlist");
	elseif sTargetRecordType == "partysheet" then
		table.insert(tAllListPaths, "treasureparcelitemlist");
	end

	return tAllListPaths;
end
function getTargetInventoryListPath(nodeTarget, sItemClass)
	local sTargetList = nil;

	local sTargetRecordType = ItemManager.getItemSourceType(nodeTarget);
	if sTargetRecordType == "charsheet" then
		sTargetList = "inventorylist";
		if ItemManager2 and ItemManager2.getCharItemListPath then
			sTargetList = ItemManager2.getCharItemListPath(nodeTarget, sItemClass);
		end
	elseif sTargetRecordType == "treasureparcel" then
		sTargetList = "itemlist";
	elseif sTargetRecordType == "partysheet" then
		sTargetList = "treasureparcelitemlist";
	elseif sTargetRecordType == "item" then
		sTargetList = "";
	end

	return sTargetList;
end
function getTransferClass(nodeItem)
	local sClass = "item";
	if ItemManager2 and ItemManager2.getItemClass then
		sClass = ItemManager2.getItemClass(nodeItem);
	end
	return sClass;
end

function handleAnyDrop(vTarget, draginfo)
	local sDragType = draginfo.getType();
	
	if not Session.IsHost then
		local sTargetType = ItemManager.getItemSourceType(vTarget);
		if sTargetType == "item" then
			return false;
		elseif sTargetType == "treasureparcel" then
			return false;
		elseif sTargetType == "partysheet" then
			if sDragType ~= "shortcut" then
				return false;
			end
			local sClass, sRecord = draginfo.getShortcutData();
			if not LibraryData.isRecordDisplayClass("item", sClass) then
				return false;
			end
			local sSourceType = ItemManager.getItemSourceType(sRecord);
			if sSourceType ~= "charsheet" then
				return false;
			end
		elseif sTargetType == "charsheet" then
			if not DB.isOwner(vTarget) then
				return false;
			end
		end
	end
	
	if sDragType == "number" then
		ItemManager.handleString(vTarget, draginfo.getDescription(), draginfo.getNumberData());
		return true;

	elseif sDragType == "string" then
		ItemManager.handleString(vTarget, draginfo.getStringData());
		return true;

	elseif sDragType == "shortcut" then
		local sClass,sRecord = draginfo.getShortcutData();
		if LibraryData.isRecordDisplayClass("item", sClass) then
			local sSourceType = ItemManager.getItemSourceType(sRecord);
			local sTargetType = ItemManager.getItemSourceType(vTarget);
			local bTransferAll = false;
			if StringManager.contains({"charsheet", "partysheet"}, sSourceType) and StringManager.contains({"charsheet", "partysheet"}, sTargetType) then
				bTransferAll = Input.isShiftPressed();
			end
			
			ItemManager.handleItem(vTarget, nil, sClass, sRecord, bTransferAll);
			return true;
		elseif sClass == "treasureparcel" then
			ItemManager.handleParcel(vTarget, sRecord);
			return true;
		end
	end
	
	return false;
end

function handleItem(vTargetRecord, sTargetList, sClass, sRecord, bTransferAll)
	local nodeTargetRecord = nil;
	if type(vTargetRecord) == "databasenode" then
		nodeTargetRecord = vTargetRecord;
	elseif type(vTargetRecord) == "string" then
		nodeTargetRecord = DB.findNode(vTargetRecord);
	end
	if not nodeTargetRecord then
		return;
	end
	
	if not sTargetList then
		sTargetList = ItemManager.getTargetInventoryListPath(nodeTargetRecord, sClass);
		if not sTargetList then
			return;
		end
	end
	
	ItemManager.sendItemTransfer(nodeTargetRecord.getPath(), sTargetList, sClass, sRecord, bTransferAll);
end

function handleCurrency(vTargetRecord, sCurrency, nCurrency)
	local sTargetRecord = nil;
	if type(vTargetRecord) == "databasenode" then
		sTargetRecord = vTargetRecord.getPath();
	elseif type(vTargetRecord) == "string" then
		sTargetRecord = vTargetRecord;
	end
	if not sTargetRecord then
		return;
	end

	ItemManager.sendCurrencyTransfer(sTargetRecord, sCurrency, nCurrency);
end

function handleParcel(vTargetRecord, sRecord)
	local sTargetRecord = nil;
	if type(vTargetRecord) == "databasenode" then
		sTargetRecord = vTargetRecord.getPath();
	elseif type(vTargetRecord) == "string" then
		sTargetRecord = vTargetRecord;
	end
	if not sTargetRecord then
		return;
	end
	
	local sTargetRecordType = getItemSourceType(vTargetRecord);
	if sTargetRecordType == "item" then
		return;
	end

	ItemManager.sendParcelTransfer(sTargetRecord, sRecord);
end

function handleString(vTargetRecord, s, n)
	local sTargetRecord = nil;
	if type(vTargetRecord) == "databasenode" then
		sTargetRecord = vTargetRecord.getPath();
	elseif type(vTargetRecord) == "string" then
		sTargetRecord = vTargetRecord;
	end
	if not sTargetRecord then
		return;
	end

	local sText = StringManager.trim(s);
	if sText == "" or sText == "-" then
		return;
	end
	
	local nCurrency = nil;
	local sCurrency = nil;
	local sTargetRecordType = ItemManager.getItemSourceType(sTargetRecord);
	if StringManager.contains({"partysheet", "charsheet", "treasureparcel"}, sTargetRecordType) then
		if n then
			nCurrency = n;
			sCurrency = CurrencyManager.getCurrencyMatch(s);
		else
			nCurrency, sCurrency = CurrencyManager.parseCurrencyString(s, true);
		end
	end
		
	if sCurrency then
		ItemManager.sendCurrencyTransfer(sTargetRecord, sCurrency, nCurrency);
	else
		ItemManager.sendItemStringTransfer(sTargetRecord, sText, n);
	end
end

function handleAnyDropOnItemRecord(vTarget, draginfo)
	if not Session.isHost and not DB.isOwner(vTarget) then
		return;
	end

	if ItemManager.isPack(vTarget) then
		local sDragType = draginfo.getType();
		if sDragType == "number" then
			local nCount = draginfo.getNumberData();
			local sItem = draginfo.getDescription();
			if ((sItem or "") ~= "") and (nCount > 0) then
				local node = DB.createChild(DB.getPath(vTarget, ItemManager.getPackIncludedItemListPath()));
				if node then
					DB.setValue(node, "name", "string", sItem);
					DB.setValue(node, "count", "number", nCount);
				end
			end
			return true;

		elseif sDragType == "string" then
			local sItem = draginfo.getDescription();
			if ((sItem or "") ~= "") then
				local node = DB.createChild(DB.getPath(vTarget, ItemManager.getPackIncludedItemListPath()));
				if node then
					DB.setValue(node, "name", "string", sItem);
					DB.setValue(node, "count", "number", 1);
				end
			end
			return true;

		elseif sDragType == "shortcut" then
			local sClass,sRecord = draginfo.getShortcutData();
			if LibraryData.isRecordDisplayClass("item", sClass) then
				local sItem = DB.getValue(DB.getPath(sRecord, "name"), "");
				local node = DB.createChild(DB.getPath(vTarget, ItemManager.getPackIncludedItemListPath()));
				if node then
					DB.setValue(node, "name", "string", sItem);
					DB.setValue(node, "count", "number", 1);
					DB.setValue(node, "link", "windowreference", sClass, sRecord);
				end
				return true;
			end
		end
	end

	return false;
end

--
-- ADD/TRANSFER ITEM
--

function sendItemTransfer (sTargetRecord, sTargetList, sClass, sRecord, bTransferAll)
	local msgOOB = {};
	msgOOB.type = ItemManager.OOB_MSGTYPE_TRANSFERITEM;
	
	msgOOB.sTarget = sTargetRecord;
	msgOOB.sTargetList = sTargetList;
	msgOOB.sClass = sClass;
	msgOOB.sRecord = sRecord;
	if bTransferAll then
		msgOOB.sTransferAll = "true";
	end

	-- If on client, go ahead and handle non-party transfers; since we're not guaranteed that GM has source open
	if not Session.IsHost then
		local sSourceRecordType = ItemManager.getItemSourceType(sRecord);
		local sTargetRecordType = ItemManager.getItemSourceType(sTargetRecord);
		if not StringManager.contains({"partysheet", "charsheet"}, sSourceRecordType) and StringManager.contains({"charsheet"}, sTargetRecordType) then
			ItemManager.handleItemTransfer(msgOOB);
			return;
		end
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleItemTransfer(msgOOB)
	ItemManager.addItemToList(DB.getPath(msgOOB.sTarget, msgOOB.sTargetList), msgOOB.sClass, msgOOB.sRecord, ((msgOOB.sTransferAll or "") == "true"));
end

function onAddItemPackLoadCallback(tCustom)
	ItemManager.addItemToList(tCustom.nodeList, tCustom.sClass, tCustom.nodeSource, tCustom.bTransferAll, tCustom.nTransferCount);
end

-- NOTE: Assumed target and source base nodes 
-- 		item = campaign, 
--		charsheet = PC inventory, 
-- 		partysheet = party inventory,
--		treasureparcel = parcel inventory
function addItemToList(vList, sClass, vSource, bTransferAll, nTransferCount)
	-- Resolve the source and target information, and make sure it's valid
	local rSourceItem = nil;
	if type(vSource) == "databasenode" then
		rSourceItem = { node = vSource };
	elseif type(vSource) == "string" then
		rSourceItem = { node = DB.findNode(vSource) };
	end
	local rTargetItem = nil;
	if type(vList) == "databasenode" then
		rTargetItem = { nodeList = vList };
	elseif type(vList) == "string" then
		rTargetItem = { nodeList = DB.createNode(vList) };
	end
	if not rSourceItem or not rTargetItem then
		return nil;
	end
	if not rSourceItem.node or not rTargetItem.nodeList then
		return nil;
	end
	rSourceItem.sClass = sClass;
	rSourceItem.bTransferAll = bTransferAll;
	rSourceItem.nTransferCount = nTransferCount;

	rSourceItem.sType = ItemManager.getItemSourceType(rSourceItem.node);
	rTargetItem.sType = ItemManager.getItemSourceType(rTargetItem.nodeList);
	
	-- Call the main item add code
	return ItemManager.helperAddItemMain(rSourceItem, rTargetItem);
end
function addStringToList(vList, sItem, nCount)
	if ((sItem or "") == "") or (nCount <= 0) then
		return nil;
	end

	-- Resolve the target information, and make sure it's valid
	local rTargetItem = nil;
	if type(vList) == "databasenode" then
		rTargetItem = { nodeList = vList };
	elseif type(vList) == "string" then
		rTargetItem = { nodeList = DB.createNode(vList) };
	end
	if not rTargetItem then
		return nil;
	end
	if not rTargetItem.nodeList then
		return nil;
	end
	rTargetItem.sType = ItemManager.getItemSourceType(rTargetItem.nodeList);

	local rSourceItem = { sClass = "string", sValue = sItem, nTransferCount = nCount, sType = "string" };

	-- Call the main item add code
	return ItemManager.helperAddItemMain(rSourceItem, rTargetItem);
end

function helperAddItemMain(rSourceItem, rTargetItem)
	-- Block unwanted transfers
	if ItemManager.helperAddItemBlockTransfer(rSourceItem, rTargetItem) then
		return nil;
	end

	-- Handle packs
	if ItemManager.handleAddItemPackTransfer(rSourceItem, rTargetItem) then
		return nil;
	end

	-- Call pre-transfer handlers; and bail if handlers say they handled the event
	if ItemManager.callPreTransferHandlers(rSourceItem, rTargetItem) then
		return nil;
	end
	
	-- Use a temporary location to create an item copy for manipulation, if the item type is supported
	local rTempItem = ItemManager.helperAddItemCreateTempNode(rTargetItem);

	-- Perform the copy
	if ItemManager.helperAddItemCopyToTempNode(rSourceItem, rTempItem, rTargetItem) then
		-- Clean up unwanted transfer fields
		ItemManager.helperAddItemCleanTempNode(rTempItem);
		-- Call cleanup-transfer handlers
		ItemManager.callCleanupTransferHandlers(rSourceItem, rTempItem, rTargetItem);
		-- Find matching target node, or create a new node
		ItemManager.helperAddItemGetTransferTargetNode(rTempItem, rTargetItem);
		-- Update item count based on source, target, and parameters
		ItemManager.helperAddItemUpdateCount(rSourceItem, rTargetItem);
		-- Perform post transfer standard events
		ItemManager.helperAddItemPostEvents(rSourceItem, rTargetItem)
	end
	
	-- Clean up temporary location
	ItemManager.helperAddItemDeleteTempNode(rTempItem);

	-- Call post-transfer handlers
	if rTargetItem.node then
		ItemManager.callPostTransferHandlers(rSourceItem, rTargetItem);
	end
	
	return rTargetItem.node;
end
function helperAddItemBlockTransfer(rSourceItem, rTargetItem)
	-- Make sure that the source and target locations are not the same character
	if rSourceItem.sType == "charsheet" and rTargetItem.sType == "charsheet" then
		if rSourceItem.node.getParent().getPath() == rTargetItem.nodeList.getPath() then
			return true;
		end
	end
	return false;
end
function handleAddItemPackTransfer(rSourceItem, rTargetItem)
	if not StringManager.contains({"charsheet", "partysheet"}, rTargetItem.sType) then
		return false;
	end
	if not ItemManager.isPack(rSourceItem.node) then
		return false;
	end
	local sSubPath = ItemManager.getPackIncludedItemListPath();
	if DB.getChildCount(rSourceItem.node, sSubPath) == 0 then
		return false;
	end

	local tRecordPaths = {};
	for _,v in pairs(DB.getChildren(rSourceItem.node, sSubPath)) do
		local sSubClass,sSubRecord = DB.getValue(v, "link", "", "");
		if LibraryData.isRecordDisplayClass("item", sSubClass) then
			table.insert(tRecordPaths, sSubRecord);
		end
	end
	local tCallback = {};
	tCallback.nodeList = rTargetItem.nodeList;
	tCallback.sClass = rSourceItem.sClass;
	tCallback.nodeSource = rSourceItem.node;
	tCallback.bTransferAll = rSourceItem.bTransferAll;
	tCallback.nTransferCount = rSourceItem.nTransferCount;
	if ModuleManager.handleRecordModulesLoad(tRecordPaths, ItemManager.onAddItemPackLoadCallback, tCallback) then
		return true;
	end

	local nPackCount = ItemManager.helperAddItemGetFinalTransferCount(rSourceItem, rTargetItem);
	for _,v in pairs(DB.getChildren(rSourceItem.node, sSubPath)) do
		local sSubClass, sSubRecord = DB.getValue(v, "link", "", "");
		local nSubCount = nPackCount * DB.getValue(v, "count", 0);
		if nSubCount > 0 then
			if LibraryData.isRecordDisplayClass("item", sSubClass) then
				ItemManager.addItemToList(rTargetItem.nodeList, sSubClass, sSubRecord, nil, nSubCount);
			else
				local sSubName = DB.getValue(v, "name", "");
				ItemManager.addStringToList(rTargetItem.nodeList, sSubName, nSubCount);
			end
		end
	end
	return true;
end
function helperAddItemCreateTempNode(rTargetItem)
	local sTempPath;
	if rTargetItem.nodeList.getParent() then
		sTempPath = rTargetItem.nodeList.getParent().getPath("temp.item");
	else
		sTempPath = "temp.item";
	end
	DB.deleteNode(sTempPath);
	return { node = DB.createNode(sTempPath), sPath = sTempPath };
end
function helperAddItemCopyToTempNode(rSourceItem, rTempItem, rTargetItem)
	if rSourceItem.sClass == "string" then
		DB.setValue(rTempItem.node, "name", "string", rSourceItem.sValue);
		DB.setValue(rTempItem.node, "count", "number", rSourceItem.nTransferCount);
		DB.setValue(rTempItem.node, "isidentified", "number", 1);
		return true;
	elseif rSourceItem.sClass == "item" then
		DB.copyNode(rSourceItem.node, rTempItem.node);
		return true;
	elseif ItemManager2 and ItemManager2.addItemToList2 then
		return ItemManager2.addItemToList2(rSourceItem.sClass, rSourceItem.node, rTempItem.node, rTargetItem.nodeList);
	elseif LibraryData.isRecordDisplayClass("item", rSourceItem.sClass) then
		DB.copyNode(rSourceItem.node, rTempItem.node);
		return true;
	end
	return false;
end
-- Remove fields that shouldn't be transferred
function helperAddItemCleanTempNode(rTempItem)
	for _,sField in ipairs(aDeleteCopyFields) do
		DB.deleteChild(rTempItem.node, sField);
	end
end
-- Determine target node for source item data.  
-- If we already have an item with the same fields, then just append the item count.  
-- Otherwise, create a new item and copy from the source item.
function helperAddItemGetTransferTargetNode(rTempItem, rTargetItem)
	if rTargetItem.sType ~= "item" then
		for _,vItem in pairs(DB.getChildren(rTargetItem.nodeList)) do
			if ItemManager.compareFields(vItem, rTempItem.node, true) then
				rTargetItem.node = vItem;
				rTargetItem.bAppend = true;
				break;
			end
		end
	end
	if not rTargetItem.node then
		rTargetItem.node = DB.createChild(rTargetItem.nodeList);
		DB.copyNode(rTempItem.node, rTargetItem.node);
	end
end
function helperAddItemGetFinalTransferCount(rSourceItem, rTargetItem)
	local bCountN = false;
	if (rSourceItem.sType == "treasureparcel" and rTargetItem.sType == "partysheet") or
			(rSourceItem.sType == "treasureparcel" and rTargetItem.sType == "charsheet") or 
			(rSourceItem.sType == "partysheet" and rTargetItem.sType == "treasureparcel") or 
			(rSourceItem.sType == "treasureparcel" and rTargetItem.sType == "treasureparcel") then
		bCountN = true;
	elseif (rSourceItem.sType == "partysheet" and rTargetItem.sType == "charsheet") or
			(rSourceItem.sType == "charsheet" and rTargetItem.sType == "charsheet") or
			(rSourceItem.sType == "charsheet" and rTargetItem.sType == "partysheet") then
		if rSourceItem.bTransferAll then
			bCountN = true;
		end
	elseif (rSourceItem.sType == "temp" and rTargetItem.sType == "charsheet") or
			(rSourceItem.sType == "temp" and rTargetItem.sType == "treasureparcel") or 
			(rSourceItem.sType == "temp" and rTargetItem.sType == "partysheet") then
		bCountN = true;
	end
	local nCount = 1;
	if bCountN or (rTargetItem.sType ~= "item") then
		if bCountN then
			nCount = DB.getValue(rSourceItem.node, "count", 0);
		elseif rSourceItem.nTransferCount then
			nCount = rSourceItem.nTransferCount;
		end
	end
	return nCount;
end
-- Determine whether to copy all items at once or just one item at a time (based on source and target)
function helperAddItemUpdateCount(rSourceItem, rTargetItem)
	rSourceItem.nFinalTransferCount = ItemManager.helperAddItemGetFinalTransferCount(rSourceItem, rTargetItem);
	if rSourceItem.nFinalTransferCount > 0 then
		DB.setValue(rTargetItem.node, "count", "number", rSourceItem.nFinalTransferCount + DB.getValue(rTargetItem.node, "count", 0));
	end
end
function helperAddItemPostEvents(rSourceItem, rTargetItem)
	if not rTargetItem.bAppend then
		DB.setValue(rTargetItem.node, "locked", "number", 1);
		if rTargetItem.sType == "charsheet" then
			ItemManager.onCharAddEvent(rTargetItem.node);
		end
	end

	-- Handle adding suffix to campaign item list copies
	if (rSourceItem.sType == "item") and (rTargetItem.sType == "item") then
		local sName = DB.getValue(rSourceItem.node, "name", "");
		if (sName ~= "") and (UtilityManager.getNodeCategory(rSourceItem.node) == UtilityManager.getNodeCategory(rTargetItem.node)) then
			DB.setValue(rTargetItem.node, "name", "string", sName .. " " .. Interface.getString("masterindex_suffix_duplicate"));
		end
	end

	-- Generate output message if transferring between characters or between party sheet and character
	if rSourceItem.sType == "charsheet" and (rTargetItem.sType == "partysheet" or rTargetItem.sType == "charsheet") then
		local sSrcName = DB.getValue(rSourceItem.node, "...name", "");
		local sTrgtName;
		if rTargetItem.sType == "charsheet" then
			sTrgtName = DB.getValue(rTargetItem.node, "...name", "");
		else
			sTrgtName = "PARTY";
		end
		local msg = {font = "msgfont", icon = "coins"};
		msg.text = "[" .. sSrcName .. "] -> [" .. sTrgtName .. "] : " .. ItemManager.getDisplayName(rTargetItem.node, true);
		if rSourceItem.nFinalTransferCount > 1 then
			msg.text = msg.text .. " (" .. rSourceItem.nFinalTransferCount .. "x)";
		end
		Comm.deliverChatMessage(msg);

		local nCharCount = DB.getValue(rSourceItem.node, "count", 0);
		if nCharCount <= rSourceItem.nFinalTransferCount then
			ItemManager.onCharRemoveEvent(rSourceItem.node);
			rSourceItem.node.delete();
		else
			DB.setValue(rSourceItem.node, "count", "number", nCharCount - rSourceItem.nFinalTransferCount);
		end
	elseif rSourceItem.sType == "partysheet" and rTargetItem.sType == "charsheet" then
		local sSrcName = "PARTY";
		local sTrgtName = DB.getValue(rTargetItem.node, "...name", "");
		local msg = {font = "msgfont", icon = "coins"};
		msg.text = "[" .. sSrcName .. "] -> [" .. sTrgtName .. "] : " .. ItemManager.getDisplayName(rTargetItem.node, true);
		if rSourceItem.nFinalTransferCount > 1 then
			msg.text = msg.text .. " (" .. rSourceItem.nFinalTransferCount .. "x)";
		end
		Comm.deliverChatMessage(msg);

		local nPartyCount = DB.getValue(rSourceItem.node, "count", 0);
		if nPartyCount <= rSourceItem.nFinalTransferCount then
			rSourceItem.node.delete();
		else
			DB.setValue(rSourceItem.node, "count", "number", nPartyCount - rSourceItem.nFinalTransferCount);
		end
	end
end
function helperAddItemDeleteTempNode(rTempItem)
	DB.deleteNode(rTempItem.sPath);
end

--
-- ADD/TRANSFER CURRENCY
--

function sendCurrencyTransfer(sTargetRecord, sCurrency, nCurrency)
	local msgOOB = {};
	msgOOB.type = ItemManager.OOB_MSGTYPE_TRANSFERCURRENCY;
	
	msgOOB.sTarget = sTargetRecord;
	msgOOB.sCurrency = sCurrency;
	msgOOB.nCurrency = nCurrency;

	Comm.deliverOOBMessage(msgOOB, "");
end

-- NOTE: Assume that we are running on host
function handleCurrencyTransfer(msgOOB)
	local nodeTargetRecord = DB.findNode(msgOOB.sTarget);
	if not nodeTargetRecord then
		return;
	end
	
	local nCurrency = tonumber(msgOOB.nCurrency) or 0;
	local sCurrency = msgOOB.sCurrency;
	
	local sTargetRecordType = ItemManager.getItemSourceType(nodeTargetRecord);
	if sTargetRecordType == "charsheet" then
		CurrencyManager.addCharCurrency(nodeTargetRecord, sCurrency, nCurrency);
	elseif sTargetRecordType == "treasureparcel" then
		local nodeTargetCoin = nil;
		local sCurrencyLower = sCurrency:lower();
		for _,vParcelCoin in pairs(DB.getChildren(nodeTargetRecord, "coinlist")) do
			if DB.getValue(vParcelCoin, "description", ""):lower() == sCurrencyLower then
				nodeTargetCoin = vParcelCoin;
			end
		end
		if not nodeTargetCoin  then
			nodeTargetCoin = DB.createChild(nodeTargetRecord, "coinlist").createChild();
			DB.setValue(nodeTargetCoin, "description", "string", sCurrency);
		end
		DB.setValue(nodeTargetCoin, "amount", "number", nCurrency + DB.getValue(nodeTargetCoin, "amount", 0));
	elseif sTargetRecordType == "partysheet" then
		local nodeCurrency = nil;
		local sCurrencyLower = sCurrency:lower();
		for _,vPSCurrency in pairs(DB.getChildren("partysheet.treasureparcelcoinlist")) do
			if DB.getValue(vPSCurrency, "description", ""):lower() == sCurrencyLower then
				nodeCurrency = vPSCurrency;
				break;
			end
		end
		
		if nodeCurrency then
			DB.setValue(nodeCurrency, "amount", "number",  DB.getValue(nodeCurrency, "amount", 0) + nCurrency);
		else
			nodeCurrency = DB.createChild("partysheet.treasureparcelcoinlist");
			DB.setValue(nodeCurrency, "description", "string", sCurrency);
			DB.setValue(nodeCurrency, "amount", "number", nCurrency);
		end
	end
end

--
-- ADD/TRANSFER PARCEL
--

function sendParcelTransfer(sTargetRecord, sSource)
	local msgOOB = {};
	msgOOB.type = ItemManager.OOB_MSGTYPE_TRANSFERPARCEL;
	
	msgOOB.sTarget = sTargetRecord;
	msgOOB.sSource = sSource;

	Comm.deliverOOBMessage(msgOOB, "");
end

-- NOTE: Assume that we are running on host
function handleParcelTransfer(msgOOB)
	local nodeTargetRecord = DB.findNode(msgOOB.sTarget);
	if not nodeTargetRecord then
		return;
	end
	
	local nodeParcel = DB.findNode(msgOOB.sSource);
	if not nodeParcel then
		return;
	end
	
	for _,vParcelItem in pairs(DB.getChildren(nodeParcel, "itemlist")) do
		ItemManager.handleItem(nodeTargetRecord, nil, "item", vParcelItem.getPath(), true);
	end
								
	for _,vParcelCoin in pairs(DB.getChildren(nodeParcel, "coinlist")) do
		local sCurrency = DB.getValue(vParcelCoin, "description", "");
		local nCurrency = DB.getValue(vParcelCoin, "amount", 0);
		ItemManager.handleCurrency(nodeTargetRecord, sCurrency, nCurrency);
	end

	local sTargetRecordType = ItemManager.getItemSourceType(nodeTargetRecord);
	if sTargetRecordType == "charsheet" then
		local msg = {font = "msgfont", icon = "coins"};
		msg.text = "Parcel [" .. DB.getValue(DB.getPath(nodeParcel, "name"), "") .. "] -> [" .. DB.getValue(DB.getPath(nodeTargetRecord, "name"), "") .. "]";
		Comm.deliverChatMessage(msg);
	end
end

--
-- ADD/TRANSFER STRING
--

function sendItemStringTransfer(sTargetRecord, sItemName, nItemCount)
	local msgOOB = {};
	msgOOB.type = ItemManager.OOB_MSGTYPE_TRANSFERITEMSTRING;
	
	msgOOB.sTarget = sTargetRecord;
	msgOOB.sName = sItemName;
	msgOOB.nCount = nItemCount;

	Comm.deliverOOBMessage(msgOOB, "");
end

-- NOTE: Assume that we are running on host
function handleItemStringTransfer(msgOOB)
	local nodeTargetRecord = DB.findNode(msgOOB.sTarget);
	if not nodeTargetRecord then
		return;
	end
	local sTargetList = ItemManager.getTargetInventoryListPath(nodeTargetRecord, sClass);
	if not sTargetList then
		return;
	end
	
	local sItem = StringManager.trim(msgOOB.sName);
	if sItem == "" or sItem == "-" then
		return;
	end
	
	local nCount = tonumber(msgOOB.nCount) or 1;
	
	ItemManager.addStringToList(DB.getPath(nodeTargetRecord, sTargetList), sItem, nCount);
end

--
-- INVENTORY SORTING
--

function onInventorySortCompare(w1, w2)
	-- Sort by containment first; empty container to bottom
	if w1.hidden_locationpath and w2.hidden_locationpath then
		local sLoc1 = w1.hidden_locationpath.getValue();
		local sLoc2 = w2.hidden_locationpath.getValue();
		if sLoc1 ~= sLoc2 then
			if sLoc1 == "" then
				if sLoc2 == "" then
					return nil;
				end
				return true;
			elseif sLoc2 == "" then
				return false;
			else
				return sLoc1 > sLoc2;
			end
		end
	end

	-- If same container, then sort by name; empty name to bottom
	local sName1 = ItemManager.getSortName(w1.getDatabaseNode());
	local sName2 = ItemManager.getSortName(w2.getDatabaseNode());
	if sName1 == "" then
		if sName2 == "" then
			return nil;
		end
		return true;
	elseif sName2 == "" then
		return false;
	elseif sName1 ~= sName2 then
		return sName1 > sName2;
	end
	
	-- Return nothing to sort by internal node name
end

function getInventorySortPath(cList, w)
	if not w.name or not w.location then
		return {}, false;
	end
	
	local sName = ItemManager.getSortName(w.getDatabaseNode());
	local sLocation = StringManager.trim(w.location.getValue()):lower();
	if (sLocation == "") or (sName == sLocation) then
		return { sName }, false;
	end
	
	for _,wList in ipairs(cList.getWindows()) do
		local sListName = ItemManager.getSortName(wList.getDatabaseNode());
		if sListName == sLocation then
			local aSortPath = ItemManager.getInventorySortPath(cList, wList);
			table.insert(aSortPath, sName);
			return aSortPath, true;
		end
	end
	return { sLocation, sName }, false;
end

function onInventorySortUpdate(cList)
	for _,w in ipairs(cList.getWindows()) do
		if not w.hidden_locationpath then
			w.createControl("hsc", "hidden_locationpath");
		end
		local aSortPath, bContained = ItemManager.getInventorySortPath(cList, w);
		w.hidden_locationpath.setValue(table.concat(aSortPath, "\a"));
		if w.name then
			if bContained then
				w.name.setAnchor("left", nil, "left", "absolute", 35 + (10 * (#aSortPath - 1)));
			else
				w.name.setAnchor("left", nil, "left", "absolute", 35);
			end
		end
		if w.nonid_name then
			if bContained then
				w.nonid_name.setAnchor("left", nil, "left", "absolute", 35 + (10 * (#aSortPath - 1)));
			else
				w.nonid_name.setAnchor("left", nil, "left", "absolute", 35);
			end
		end
	end
	
	cList.applySort();
end
