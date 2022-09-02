-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		Comm.registerSlashHandler("export", ExportManager.processExport);
	end
	ExportManager.registerPreExportCallback(ExportManager.callbackCleanLocks);
	ExportManager.registerPostExportCallback(ExportManager.callbackRestoreLocks);
	ExportManager.registerPreExportCallback(ExportManager.callbackReferenceImageCheck);
	ExportManager.registerPreExportCallback(ExportManager.callbackCleanCharacterPortraitTokens);
	ExportManager.registerPostExportCallback(ExportManager.callbackRestoreCharacterPortraitTokens);
	ExportManager.registerPreExportCallback(ExportManager.callbackGenerateReferenceKeywords);
end

function processExport(sCommand, sParams)
	Interface.openWindow("export", "export");
end

-- 
--	Export node registration
--

local _tExport = {};

function retrieveExportNodes()
	return _tExport;
end
function registerExportNode(rExport)
	table.insert(_tExport, rExport)
end
function unregisterExportNode(rExport)
	local nIndex = nil;
	
	for k,v in pairs(_tExport) do
		if string.upper(v.name) == string.upper(rExport.name) then
			nIndex = k;
		end
	end
	
	if nIndex then
		table.remove(_tExport, nIndex);
	end
end

--
--	Export callback registration
--

local _tPreExportCallbacks = {};
local _tPostExportCallbacks = {};

function registerPreExportCallback(fn)
	UtilityManager.registerCallback(_tPreExportCallbacks, fn);
end
function unregisterPreExportCallback(fCallback)
	UtilityManager.unregisterCallback(_tPreExportCallbacks, fn);
end
function performPreExportCallback(...)
	UtilityManager.performAllCallbacks(_tPreExportCallbacks, ...);
end

function registerPostExportCallback(fn)
	UtilityManager.registerCallback(_tPostExportCallbacks, fn);
end
function unregisterPostExportCallback(fn)
	UtilityManager.unregisterCallback(_tPostExportCallbacks, fn);
end
function performPostExportCallback(...)
	UtilityManager.performAllCallbacks(_tPostExportCallbacks, ...);
end

--
--	Export window support
--

local _tExportProperties = {};
local _tExportNodes = {};
local _tExportAssets = {};
local _tExportAssetRewrites = {};

function isFileNameValid(sFile)
	if (sFile or "") == "" then
		return false;
	end
	if sFile:match("[\\/<>|:?*%%]") then
		return false;
	end
	return true;
end

function performInit(wExport)
	local tExports = ExportManager.retrieveExportNodes();
	
	for _,rExport in ipairs(tExports) do
		local wRecordType = wExport.recordtypes.createWindow("export.recordtypes." .. rExport.name);
		wRecordType.setData(rExport);

		local tViews = LibraryData.getRecordViews(rExport.name);
		if tViews then
			for kView, tView in pairs(tViews) do
				local wRecordView = wExport.recordviews.createWindow("export.recordviews." .. rExport.name .. "." .. kView);
				local tRecordView = {};
				tRecordView.sRecordType = rExport.name;
				tRecordView.sRecordView = kView;
				tRecordView.sLabel = tView.sExportDisplayText;
				wRecordView.setData(tRecordView);
			end
		end
	end
	
	wExport.recordtypes.applySort();
	wExport.recordviews.applySort();
end

function performClear(wExport)
	wExport.file.setValue("");
	wExport.thumbnail.setValue("");
	
	wExport.name.setValue("");
	wExport.category.setValue("");
	wExport.author.setValue("");
	wExport.readonly.setValue(0);
	wExport.playervisible.setValue(0);

	for _,wRecordType in ipairs(wExport.recordtypes.getWindows()) do
		wRecordType.select.setValue(0);

		local tEntriesToDelete = {};
		for _,wRecordTypeSingle in ipairs(wRecordType.entries.getWindows()) do
			table.insert(tEntriesToDelete, wRecordTypeSingle.getDatabaseNode());
		end
		for _,node in ipairs(tEntriesToDelete) do
			node.delete();
		end
	end

	for _,wRecordView in ipairs(wExport.recordviews.getWindows()) do
		wRecordView.select.setValue(0);
	end

	local tNodesToDelete = {};
	for _,wAsset in ipairs(wExport.assets.getWindows()) do
		table.insert(tNodesToDelete, wAsset.getDatabaseNode());
	end
	for _,node in ipairs(tNodesToDelete) do
		node.delete();
	end
end

function isExportNode(sPath)
	return (_tExportNodes[sPath] ~= nil);
end
function setExportNode(sPath, tNode)
	_tExportNodes[sPath] = tNode;
end

function addExportNode(nodeSource, sTargetPath, sExportType, sExportLabel, sExportListClass, sExportRootPath)
	if ((sExportType or "") == "") then
		return; 
	end
	
	-- Create reference node
	if _tExportProperties.readonly then
		if not ExportManager.isExportNode("reference") then
			ExportManager.setExportNode("reference", { static = true });
		end
	end
	
	-- Create node entry
	local tExportNode = {};
	tExportNode.import = nodeSource.getPath();
	tExportNode.category = nodeSource.getCategory();
	ExportManager.setExportNode(sTargetPath, tExportNode);
	
	-- Create library entry
	if ((sExportListClass or "") ~= "") then
		if not ExportManager.hasExportLibraryEntry(sExportType) then
			local tLibraryEntry = {};
			if sExportListClass == "reference_list" then
				tLibraryEntry.createstring = { name = sExportLabel, recordtype = sExportType };
				tLibraryEntry.createlink = { librarylink = { class = sExportListClass, recordname = ".." } };
			else
				tLibraryEntry.createstring = { name = sExportLabel };
				tLibraryEntry.createlink = { librarylink = { class = sExportListClass, recordname = sExportRootPath } };
			end
			ExportManager.addExportLibraryEntry(sExportType, tLibraryEntry);
		end
	end
end
function addExportRecordView(tRecordViewData)
	-- Create list entry
	if not ExportManager.isExportNode("list") then
		ExportManager.setExportNode("list", { static = true });
	end
	local sRecordViewListPath = string.format("list.%s.%s", tRecordViewData.sRecordType, tRecordViewData.sRecordView);
	local tRecordViewEntry = {};
	tRecordViewEntry.createstring = { recordtype = tRecordViewData.sRecordType, listview = tRecordViewData.sRecordView };
	ExportManager.setExportNode(sRecordViewListPath, tRecordViewEntry);

	-- Create library entry
	local sLibraryEntryTag = string.format("%s_%s", tRecordViewData.sRecordType, tRecordViewData.sRecordView);
	if not ExportManager.hasExportLibraryEntry(sLibraryEntryTag) then
		local tLibraryEntry = {};
		tLibraryEntry.createstring = { name = tRecordViewData.sLabel };
		tLibraryEntry.createlink = { librarylink = { class = "reference_groupedlist", recordname = sRecordViewListPath } };
		ExportManager.addExportLibraryEntry(sLibraryEntryTag, tLibraryEntry);
	end
end

function hasExportLibraryEntry(sLibraryEntryTag)
	local sLibraryNode = "library." .. _tExportProperties.namecompact;
	if not ExportManager.isExportNode(sLibraryNode) then
		return false;
	end
	local sLibraryEntryPath = string.format("%s.entries.%s", sLibraryNode, sLibraryEntryTag);
	if not ExportManager.isExportNode(sLibraryEntryPath) then
		return false;
	end
	return true;
end
function addExportLibraryEntry(sLibraryEntryTag, tLibraryEntry)
	local sLibraryNode = "library." .. _tExportProperties.namecompact;
	if not ExportManager.isExportNode(sLibraryNode) then
		local tLibraryIndex = {};
		tLibraryIndex.createstring = { name = _tExportProperties.namecompact, categoryname = _tExportProperties.category };
		tLibraryIndex.static = true;
		ExportManager.setExportNode(sLibraryNode, tLibraryIndex);
	end
	local sLibraryEntryPath = string.format("%s.entries.%s", sLibraryNode, sLibraryEntryTag);
	ExportManager.setExportNode(sLibraryEntryPath, tLibraryEntry);
end
-- Example: ["images/Map-Thistletop-Dungeon-1.png"] = "referenceimages/Map-Thistletop-Dungeon-1.png",
function addExportAssetRewrite(sSource, sTarget)
	_tExportAssetRewrites[sSource] = sTarget;
end
function isExportAsset(sAsset)
	return StringManager.contains(_tExportAssets, sAsset);
end

function performExport(wExport)
	-- Reset data
	_tExportProperties = {};
	_tExportNodes = {};
	_tExportAssets = {};
	_tExportAssetRewrites = {};

	-- Global properties
	_tExportProperties.name = StringManager.trim(wExport.name.getValue());
	_tExportProperties.namecompact = _tExportProperties.name:gsub("%W", ""):lower();
	_tExportProperties.category = StringManager.trim(wExport.category.getValue());
	_tExportProperties.filename = StringManager.trim(wExport.file.getValue());
	_tExportProperties.author = StringManager.trim(wExport.author.getValue());
	_tExportProperties.thumbnail = StringManager.trim(wExport.thumbnail.getValue());
	_tExportProperties.readonly = (wExport.readonly.getValue() == 1);
	_tExportProperties.playervisible = (wExport.playervisible.getValue() == 1);

	_tExportProperties.displayname = StringManager.trim(wExport.displayname.getValue());
	if _tExportProperties.displayname == _tExportProperties.name then
		_tExportProperties.displayname = "";
	end
	if wExport.anyruleset.getValue() == 1 then
		_tExportProperties.ruleset = "";
	else
		_tExportProperties.ruleset = Interface.getRuleset();
	end

	-- Pre checks
	if (_tExportProperties.name or "") == "" then
		ChatManager.SystemMessage(Interface.getString("export_error_name"));
		wExport.name.setFocus(true);
		return;
	end
	if (_tExportProperties.filename or "") == "" then
		ChatManager.SystemMessage(Interface.getString("export_error_file_empty"));
		wExport.file.setFocus(true);
		return;
	end
	if not ExportManager.isFileNameValid(_tExportProperties.filename) then
		ChatManager.SystemMessage(Interface.getString("export_error_file_invalid"));
		wExport.file.setFocus(true);
		return;
	end
	
	-- Assets
	for _,wAsset in ipairs(wExport.assets.getWindows()) do
		table.insert(_tExportAssets, wAsset.token.getValue());
	end
	
	-- Record Types
	local tExportedRecordTypes = {};
	for _,wRecordType in ipairs(wExport.recordtypes.getWindows()) do
		local aExportSources = wRecordType.getSources();
		local aExportTargets;
		if _tExportProperties.readonly then
			aExportTargets = wRecordType.getRefTargets();
		else
			aExportTargets = wRecordType.getTargets();
		end
		if (#aExportSources > 0) and (#aExportSources == #aExportTargets) then
			local sExportType = wRecordType.getExportType();
			local sExportLabel = wRecordType.label.getValue();
			local sExportListClass = wRecordType.getExportListClass();
			local sExportListPath = wRecordType.getExportListPath() or aExportTargets[1];

			if wRecordType.select.getValue() == 1 then
				ExportManager.performPreExportCallback(sExportType);

				-- Loop through all campaign records of this record type
				for kSource,vSource in ipairs(aExportSources) do
					local nodeSource = DB.findNode(vSource);
					if nodeSource then
						for _,nodeChild in pairs(nodeSource.getChildren()) do
							if nodeChild.getType() == "node" then
								local sTargetPath = nodeChild.getPath():gsub("^" .. vSource, aExportTargets[kSource]);
								ExportManager.addExportNode(nodeChild, sTargetPath, sExportType, sExportLabel, sExportListClass, sExportListPath);
								tExportedRecordTypes[sExportType] = true;
							end
						end
					end
				end
			else
				-- Loop through record type singles
				local tSingles = {};
				for _,wRecordTypeSingle in ipairs(wRecordType.entries.getWindows()) do
					local _,sRecordTypeSinglePath = wRecordTypeSingle.link.getValue();
					table.insert(tSingles, sRecordTypeSinglePath)
				end

				if #tSingles > 0 then
					ExportManager.performPreExportCallback(sExportType, tSingles);

					local bExportedAtLeastOne = false;
					for _,sRecordTypeSinglePath in ipairs(tSingles) do
						local nodeRecordTypeSingle = DB.findNode(sRecordTypeSinglePath);
						if nodeRecordTypeSingle then
							for kSource,vSource in ipairs(aExportSources) do
								if sRecordTypeSinglePath:match("^" .. vSource) then
									sRecordTypeSinglePath = sRecordTypeSinglePath:gsub("^" .. vSource, aExportTargets[kSource]);
									break;
								end
							end
							ExportManager.addExportNode(nodeRecordTypeSingle, sRecordTypeSinglePath, sExportType, sExportLabel, sExportListClass, sExportListPath);
							bExportedAtLeastOne = true;
						end
					end

					if bExportedAtLeastOne then
						tExportedRecordTypes[sExportType] = tSingles;
					end
				end
			end
		end
	end
	ExportManager.performPreExportCallback("");

	-- Record Views
	for _,wRecordView in ipairs(wExport.recordviews.getWindows()) do
		if (wRecordView.select.getValue() == 1) then
			local tRecordViewData = wRecordView.getData();
			if tExportedRecordTypes[tRecordViewData.sRecordType] then
				ExportManager.addExportRecordView(tRecordViewData);
			end
		end
	end
	
	-- Export
	local tExport = {
		name = _tExportProperties.name,
		displayname = _tExportProperties.displayname,
		ruleset = _tExportProperties.ruleset,
		category = _tExportProperties.category,
		author = _tExportProperties.author,
		filename = _tExportProperties.filename,
		thumbnail = _tExportProperties.thumbnail,
		playervisible = _tExportProperties.playervisible,
		exportnodes = _tExportNodes,
		exportassets = _tExportAssets,
		assetrewrites = _tExportAssetRewrites,
	};
	local bSuccess = Module.export(tExport);

	-- Post callbacks
	for sExportType,v in pairs(tExportedRecordTypes) do
		if type(v) == "table" then
			ExportManager.performPostExportCallback(sExportType, v);
		else
			ExportManager.performPostExportCallback(sExportType);
		end
	end
	ExportManager.performPostExportCallback("");
	
	if bSuccess then
		ChatManager.SystemMessage(Interface.getString("export_message_success"));
	else
		ChatManager.SystemMessage(Interface.getString("export_message_failure"));
	end
end

--
--	Default cleanup callback
--

local _tCleanedLocks = {};

function callbackCleanLocks(sRecordType, tRecords)
	if sRecordType == "" then
		return;
	end

	_tCleanedLocks[sRecordType] = {};
	if tRecords then
		for _,sRecord in ipairs(tRecords) do
			local node = DB.findNode(sRecord);
			ExportManager.cleanRecordLocks(sRecordType, node);
		end
	else
		local tMappings = LibraryData.getMappings(sRecordType);
		for _,sMapping in ipairs(tMappings) do
			for _,node in pairs(DB.getChildren(sMapping)) do
				ExportManager.cleanRecordLocks(sRecordType, node);
			end
		end
	end
end
function cleanRecordLocks(sRecordType, node)
	if not node then
		return;
	end
	for sChild,nodeChild in pairs(node.getChildren()) do
		if nodeChild.getType() == "node" then
			ExportManager.cleanRecordLocks(sRecordType, nodeChild);
		elseif sChild == "locked" then
			if nodeChild.getValue() == 1 then
				table.insert(_tCleanedLocks[sRecordType], nodeChild.getPath());
			end
			nodeChild.delete();
		end
	end
end

function callbackRestoreLocks(sRecordType, tRecords)
	if sRecordType == "" then
		return;
	end
	
	if _tCleanedLocks[sRecordType] then
		for _,sPath in ipairs(_tCleanedLocks[sRecordType]) do
			DB.setValue(sPath, "number", 1);
		end
	end
end

-- Example: ["images/Map-Thistletop-Dungeon-1.png"] = "referenceimages/Map-Thistletop-Dungeon-1.png",
local _tImageRewriteChecks = {};
function callbackReferenceImageCheck(sRecordType, tRecords)
	if sRecordType == "" then
		for sAsset,bLink in pairs(_tImageRewriteChecks) do
			if not bLink then
				if not ExportManager.isExportAsset(sAsset) then
					if StringManager.startsWith(sAsset, "images/") then
						ExportManager.addExportAssetRewrite(sAsset, sAsset:gsub("^images/", "referenceimages/"));
					elseif StringManager.startsWith(sAsset, "campaign/images/") then
						ExportManager.addExportAssetRewrite(sAsset:gsub("^campaign/images/", "images/"), sAsset:gsub("^campaign/images/", "referenceimages/"));
					end
				end
			end
		end
		_tImageRewriteChecks = {};
	elseif sRecordType == "referencemanualpage" then
		if tRecords then
			for _,sRecord in ipairs(tRecords) do
				local node = DB.findNode(sRecord);
				ExportManager.checkManualImageRef(node);
			end
		else
			RecordManager.callForEachCampaignRecord(sRecordType, ExportManager.checkManualImageRef);
		end
	elseif sRecordType == "image" then
		if tRecords then
			for _,sRecord in ipairs(tRecords) do
				local node = DB.findNode(sRecord);
				ExportManager.checkRegularImageRef(node);
			end
		else
			RecordManager.callForEachCampaignRecord(sRecordType, ExportManager.checkRegularImageRef);
		end
	end
end
function checkManualImageRef(node)
	if not node then
		return;
	end
	for _,nodeBlock in pairs(DB.getChildren(node, "blocks")) do
		local sAsset = DB.getText(nodeBlock, "image", "");
		if sAsset ~= "" then
			local sLinkClass, sLinkRecord = DB.getValue(nodeBlock, "imagelink", "", "");
			local bHasLink = (sLinkClass ~= "") and (sLinkRecord ~= "");
			if bHasLink then
				_tImageRewriteChecks[sAsset] = true;
			elseif not _tImageRewriteChecks[sAsset] then
				_tImageRewriteChecks[sAsset] = false;
			end
		end
	end
end
function checkRegularImageRef(node)
	if not node then
		return;
	end
	local sAsset = DB.getText(node, "image", "");
	if sAsset ~= "" then
		_tImageRewriteChecks[sAsset] = true;
	end
end

local _tCleanedCharacterTokens = {};
function callbackCleanCharacterPortraitTokens(sRecordType, tRecords)
	if sRecordType == "charsheet" then
		_tCleanedCharacterTokens = {};
		if tRecords then
			for _,sRecord in ipairs(tRecords) do
				ExportManager.cleanCharacterPortraitTokens(DB.findNode(sRecord));
			end
		else
			RecordManager.callForEachCampaignRecord(sRecordType, ExportManager.cleanCharacterPortraitTokens);
		end
	end
end
function cleanCharacterPortraitTokens(node)
	if not node then
		return;
	end
	local sToken = DB.getValue(node, "token", "");
	if ((#sToken ~= "") and (sToken:sub(1,9) == "portrait_")) then
		table.insert(_tCleanedCharacterTokens, node.getPath());
		DB.setValue(node, "token", "token", "");
	end
end

function callbackRestoreCharacterPortraitTokens(sRecordType, tRecords)
	if sRecordType == "charsheet" then
		for _,sPath in ipairs(_tCleanedCharacterTokens) do
			local node = DB.findNode(sPath);
			if node then
				DB.setValue(node, "token", "token", "portrait_" .. node.getName() .. "_token");
			end
		end
	end
end

function callbackGenerateReferenceKeywords(sRecordType, tRecords)
	if sRecordType == "referencemanualpage" then
		ReferenceManualManager.onCampaignKeywordGen();
	end
end
