-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CombatRecordManager.addStandardCombatRecordTypes();
end

--
--	Record type registration
--

local _tRecordTypeCallbacks = {};
function setRecordTypeCallback(sRecordType, fn)
	UtilityManager.setKeySingleCallback(_tRecordTypeCallbacks, sRecordType, fn);
end
function getRecordTypeCallback(sRecordType)
	return UtilityManager.getKeySingleCallback(_tRecordTypeCallbacks, sRecordType);
end
function hasRecordTypeCallback(sRecordType)
	return UtilityManager.hasKeySingleCallback(_tRecordTypeCallbacks, sRecordType);
end
function onRecordTypeEvent(sRecordType, tCustom)
	tCustom.sRecordType = sRecordType;
	if not tCustom.nodeRecord then
		tCustom.nodeRecord = DB.findNode(tCustom.sRecord);
	end
	local bResult = UtilityManager.performKeySingleCallback(_tRecordTypeCallbacks, sRecordType, tCustom);
	if bResult then
		CombatRecordManager.onRecordTypePostAddEvent(tCustom.sRecordType, tCustom);
	end
	return bResult;
end

local _tRecordTypePostAddCallbacks = {};
function setRecordTypePostAddCallback(sRecordType, fn)
	UtilityManager.setKeySingleCallback(_tRecordTypePostAddCallbacks, sRecordType, fn);
end
function getRecordTypePostAddCallback(sRecordType)
	return UtilityManager.getKeySingleCallback(_tRecordTypePostAddCallbacks, sRecordType);
end
function hasRecordTypePostAddCallback(sRecordType)
	return UtilityManager.hasKeySingleCallback(_tRecordTypePostAddCallbacks, sRecordType);
end
function onRecordTypePostAddEvent(sRecordType, tCustom)
	return UtilityManager.performKeySingleCallback(_tRecordTypePostAddCallbacks, sRecordType, tCustom);
end

--
--	Standard Support
--

function addStandardCombatRecordTypes()
	if Session.IsHost then
		if not CombatRecordManager.hasRecordTypeCallback("charsheet") then
			CombatRecordManager.setRecordTypeCallback("charsheet", CombatRecordManager.onPCAdd);
		end
		if not CombatRecordManager.hasRecordTypeCallback("npc") then
			CombatRecordManager.setRecordTypeCallback("npc", CombatRecordManager.onNPCAdd);
		end
		if not CombatRecordManager.hasRecordTypeCallback("battle") then
			CombatRecordManager.setRecordTypeCallback("battle", CombatRecordManager.onBattleAdd);
		end
	end
end
-- NOTE: The combat tracker entries must be aware of "vehicle" 
--		record types to display correctly;
--		unless vehicles have "exactly" the same fields as NPCs.
function addStandardVehicleCombatRecordType()
	if not LibraryData.isRecordType("vehicle") then
		return;
	end

	local t = LibraryData.getCustomData("battle", "acceptdrop") or { "npc" };
	if not StringManager.contains(t, "vehicle") then
		table.insert(t, "vehicle");
		LibraryData.setCustomData("battle", "acceptdrop", t);
	end

	if Session.IsHost then
		CombatRecordManager.setRecordTypeCallback("vehicle", CombatRecordManager.onVehicleAdd);
	end
end

-- NOTE: Creates combatant node, 
--		and clears active, tokenrefid, tokenrefnode, locked, effects
function handleStandardCombatAdd(tCustom)
	if not tCustom.nodeRecord then
		return;
	end
	tCustom.nodeCT = CombatManager.createCombatantNode();
	if not tCustom.nodeCT then
		return;
	end
	DB.copyNode(tCustom.nodeRecord, tCustom.nodeCT);

	-- Remove any combatant specific information
	DB.setValue(tCustom.nodeCT, "active", "number", 0);
	DB.setValue(tCustom.nodeCT, "tokenrefid", "string", "");
	DB.setValue(tCustom.nodeCT, "tokenrefnode", "string", "");
	DB.deleteChildren(tCustom.nodeCT, "effects");
	
	-- Lock record view by default when copying to CT
	DB.setValue(tCustom.nodeCT, "locked", "number", 1);
end
-- NOTE: Sets name, nonid_name, isidentified, link, sourcelink, friendfoe, token
function handleStandardCombatAddFields(tCustom)
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	local nodeSource = tCustom.nodeRecord;
	local tCurrentCombatants = CombatManager.getCombatantNodes();

	if (tCustom.sFaction or "") == "" then
		tCustom.sFaction = "foe";
	end

	-- Get the name to use for this addition
	local bIsCTSource = (UtilityManager.getRootNodeName(nodeSource) == CombatManager.CT_MAIN_PATH);
	local sNameLocal = tCustom.sName;
	if not sNameLocal then
		sNameLocal = DB.getValue(nodeSource, "name", "");
		if bIsCTSource then
			sNameLocal = CombatManager.stripCreatureNumber(sNameLocal);
		end
	end
	local sNonIDLocal = DB.getValue(nodeSource, "nonid_name", "");
	if sNonIDLocal == "" then
		if tCustom.sRecordType then
			sNonIDLocal = Interface.getString("library_recordtype_empty_nonid_" .. tCustom.sRecordType);
		end
		if sNonIDLocal == "" then
			sNonIDLocal = Interface.getString("library_recordtype_empty_nonid_npc");
		end
	elseif bIsCTSource then
		sNonIDLocal = CombatManager.stripCreatureNumber(sNonIDLocal);
	end
	
	local nLocalID = DB.getValue(nodeSource, "isidentified", 1);
	if not bIsCTSource then
		local sSourcePath = nodeSource.getPath()
		local aMatches = {};
		for _,v in pairs(tCurrentCombatants) do
			if v ~= tCustom.nodeCT then
				local _,sRecord = DB.getValue(v, "sourcelink", "", "");
				if sRecord == sSourcePath then
					table.insert(aMatches, v);
				end
			end
		end
		if #aMatches > 0 then
			nLocalID = 0;
			for _,v in ipairs(aMatches) do
				if DB.getValue(v, "isidentified", 1) == 1 then
					nLocalID = 1;
				end
			end
		end
	end
	
	local nodeLastMatch = nil;
	if sNameLocal:len() > 0 then
		-- Determine the number of NPCs with the same name
		local nNameHigh = 0;
		local aMatchesWithNumber = {};
		local aMatchesToNumber = {};
		for _,v in pairs(tCurrentCombatants) do
			if v ~= tCustom.nodeCT and (DB.getValue(v, "friendfoe", "") == tCustom.sFaction) then
				local sEntryName = DB.getValue(v, "name", "");
				local sTemp, sNumber = CombatManager.stripCreatureNumber(sEntryName);
				if sTemp == sNameLocal then
					nodeLastMatch = v;
					
					local nNumber = tonumber(sNumber) or 0;
					if nNumber > 0 then
						nNameHigh = math.max(nNameHigh, nNumber);
						table.insert(aMatchesWithNumber, v);
					else
						table.insert(aMatchesToNumber, v);
					end
				end
			end
		end
	
		-- If multiple NPCs of same name, then figure out whether we need to adjust the name based on options
		local sOptNNPC = OptionsManager.getOption("NNPC");
		if sOptNNPC ~= "off" then
			local nNameCount = #aMatchesWithNumber + #aMatchesToNumber;
			
			for _,v in ipairs(aMatchesToNumber) do
				local sEntryName = DB.getValue(v, "name", "");
				local sEntryNonIDName = DB.getValue(v, "nonid_name", "");
				if sEntryNonIDName == "" then
					sEntryNonIDName = Interface.getString("library_recordtype_empty_nonid_npc");
				end
				if sOptNNPC == "append" then
					nNameHigh = nNameHigh + 1;
					DB.setValue(v, "name", "string", sEntryName .. " " .. nNameHigh);
					DB.setValue(v, "nonid_name", "string", sEntryNonIDName .. " " .. nNameHigh);
				elseif sOptNNPC == "random" then
					local sNewName, nSuffix = CombatManager.randomName(sEntryName);
					DB.setValue(v, "name", "string", sNewName);
					DB.setValue(v, "nonid_name", "string", sEntryNonIDName .. " " .. nSuffix);
				end
			end
			
			if nNameCount > 0 then
				if sOptNNPC == "append" then
					nNameHigh = nNameHigh + 1;
					sNameLocal = sNameLocal .. " " .. nNameHigh;
					sNonIDLocal = sNonIDLocal .. " " .. nNameHigh;
				elseif sOptNNPC == "random" then
					local sNewName, nSuffix = CombatManager.randomName(sNameLocal);
					sNameLocal = sNewName;
					sNonIDLocal = sNonIDLocal .. " " .. nSuffix;
				end
			end
		end
	end
	tCustom.nodeCTLastMatch = nodeLastMatch;

	-- Final name handling
	DB.setValue(tCustom.nodeCT, "name", "string", sNameLocal);
	DB.setValue(tCustom.nodeCT, "nonid_name", "string", sNonIDLocal);
	local nID = tCustom.nIdentified or nLocalID;
	DB.setValue(tCustom.nodeCT, "isidentified", "number", nID);
	tCustom.sFinalName = sNameLocal;

	-- Link handling
	local sClass = tCustom.sClass or LibraryData.getRecordDisplayClass(tCustom.sRecordType);
	DB.setValue(tCustom.nodeCT, "link", "windowreference", "", ""); -- Workaround to force field update on client; client does not pass network update to other clients if setValue creates value node with default value
	DB.setValue(tCustom.nodeCT, "link", "windowreference", sClass, "");
	if not bIsCTSource then
		DB.setValue(tCustom.nodeCT, "sourcelink", "windowreference", sClass, nodeSource.getPath());
	end

	-- Faction handling
	DB.setValue(tCustom.nodeCT, "friendfoe", "string", tCustom.sFaction);

	-- Token handling
	CombatRecordManager.handleStandardCombatAddToken(tCustom);
end
function handleStandardCombatAddToken(tCustom)
	if not tCustom.nodeCT or not tCustom.nodeRecord then
		return;
	end

	local sToken = tCustom.sToken or DB.getValue(tCustom.nodeRecord, "token", "");
	if sToken == "" or not Interface.isToken(sToken) then
		local sName = tCustom.sFinalName;
		if not sName then
			sName = DB.getValue(tCustom.nodeRecord, "name", "");
		end
		local sLetter;
		if (sName or "") ~= "" then
			sLetter = StringManager.trim(sName):match("^([a-zA-Z])"):lower();
		end
		if sLetter then
			sToken = "tokens/Medium/" .. sLetter .. ".png@Letter Tokens";
		else
			sToken = "tokens/Medium/z.png@Letter Tokens";
		end
	end
	DB.setValue(tCustom.nodeCT, "token", "token", sToken);
end
function handleStandardCombatAddSpaceReach(tCustom)
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	local nSpace, nReach = ActorCommonManager.getSpaceReach(tCustom.nodeRecord);
	DB.setValue(tCustom.nodeCT, "space", "number", nSpace);
	DB.setValue(tCustom.nodeCT, "reach", "number", nReach);
end
function handleStandardCombatAddPlacement(tCustom)
	if not tCustom.nodeCT then
		return;
	end
	if (tCustom.tPlacement or "") == "" then
		return;
	end

	local sToken = DB.getValue(tCustom.nodeCT, "token", "");
	if not Interface.isToken(sToken) then
		return;
	end
	local sRecord = tCustom.tPlacement.imagelink;
	if (sRecord or "") == "" then
		return;
	end
	local nodeImage = DB.findNode(sRecord);
	if not nodeImage then
		return;
	end

	TokenManager.setDragTokenUnits(DB.getValue(tCustom.nodeCT, "space"));
	local tokenAdded = Token.addToken(nodeImage, sToken, tCustom.tPlacement.imagex, tCustom.tPlacement.imagey);
	TokenManager.endDragTokenWithUnits(tCustom.nodeCT);
	if tokenAdded then
		TokenManager.linkToken(tCustom.nodeCT, tokenAdded);
	end
end

function handleStandardCombatAddPCFields(tCustom)
	if not tCustom.nodeCT or not tCustom.nodeRecord then
		return;
	end

	DB.setValue(tCustom.nodeCT, "link", "windowreference", tCustom.sClass, tCustom.nodeRecord.getPath());
	DB.setValue(tCustom.nodeCT, "friendfoe", "string", "friend");
end
function handleStandardCombatAddPCToken(tCustom)
	if not tCustom.nodeCT or not tCustom.nodeRecord then
		return;
	end

	local sToken = DB.getValue(tCustom.nodeRecord, "token");
	if (sToken or "") == "" then
		sToken = "portrait_" .. tCustom.nodeRecord.getName() .. "_token"
	end
	DB.setValue(tCustom.nodeCT, "token", "token", sToken);
end

function handleCombatAddInitDnD(tCustom)
	local sOptINIT = OptionsManager.getOption("INIT");
	local nInit;
	if sOptINIT == "group" then
		if tCustom.nodeCTLastMatch then
			nInit = DB.getValue(tCustom.nodeCTLastMatch, "initresult", 0);
		else
			nInit = math.random(20) + DB.getValue(tCustom.nodeCT, "init", 0);
		end
	elseif sOptINIT == "on" then
		nInit = math.random(20) + DB.getValue(tCustom.nodeCT, "init", 0);
	else
		return;
	end

	DB.setValue(tCustom.nodeCT, "initresult", "number", nInit);
end

--
--	PC Record
--

function onPCAdd(tCustom)
	CombatRecordManager.addPC(tCustom);
	return true;
end
function addPC(tCustom)
	if not tCustom.nodeRecord then
		return;
	end

	-- Handle legacy override
	local fOverride = CombatManager.getCustomAddPC();
	if fOverride then
		fOverride(tCustom.nodeRecord);
		return;
	end
	
	-- Standard handling
	CombatRecordManager.handleStandardCombatAdd(tCustom);
	if not tCustom.nodeCT then
		return;
	end
	
	CombatRecordManager.handleStandardCombatAddPCFields(tCustom);
	CombatRecordManager.handleStandardCombatAddSpaceReach(tCustom);
	
	CombatRecordManager.handleStandardCombatAddPCToken(tCustom);
end

--
--	NPC Record
--

function onNPCAdd(tCustom)
	CombatRecordManager.addNPC(tCustom);
	return true;
end
function addNPC(tCustom)
	if not tCustom.nodeRecord then
		return;
	end

	-- Handle legacy override
	local fOverride = CombatManager.getCustomAddNPC();
	if fOverride then
		tCustom.nodeCT = fOverride(tCustom.sClass, tCustom.nodeRecord, tCustom.sName);
		CombatRecordManager.handleStandardCombatAddPlacement(tCustom);
		return;
	end
	
	-- Standard handling
	CombatRecordManager.addNPCHelper(tCustom);
	if not tCustom.nodeCT then
		return;
	end

	-- Placement
	CombatRecordManager.handleStandardCombatAddPlacement(tCustom);
end
function addNPCHelper(tCustom)
	if not tCustom.nodeRecord then
		return nil;
	end

	-- Standard handling
	CombatRecordManager.handleStandardCombatAdd(tCustom);
	if not tCustom.nodeCT then
		return nil;
	end

	CombatRecordManager.handleStandardCombatAddFields(tCustom);
	CombatRecordManager.handleStandardCombatAddSpaceReach(tCustom);
end

--
--	Vehicle Record
--

function onVehicleAdd(tCustom)
	CombatRecordManager.addVehicle(tCustom);
	return true;
end
function addVehicle(tCustom)
	if not tCustom.nodeRecord then
		return;
	end

	-- Standard handling
	CombatRecordManager.handleStandardCombatAdd(tCustom);
	if not tCustom.nodeCT then
		return nil;
	end

	CombatRecordManager.handleStandardCombatAddFields(tCustom);
	CombatRecordManager.handleStandardCombatAddSpaceReach(tCustom);

	-- Placement
	CombatRecordManager.handleStandardCombatAddPlacement(tCustom);
end

--
--	Battle Record
--

function onBattleAdd(tCustom)
	CombatRecordManager.addBattle(tCustom);
	return true;
end
function addBattle(tCustom)
	-- Setup
	if not tCustom.nodeRecord then
		return;
	end
	tCustom.sListPath = LibraryData.getCustomData("battle", "npclist") or "npclist";

	-- Handle module load, since battle entries are "linked", not copied.
	if CombatRecordManager.handleBattleModuleLoad(tCustom) then
		return;
	end

	-- Handle legacy override
	local fOverride = CombatManager.getCustomAddBattle()
	if fOverride then
		fOverride(tCustom.nodeRecord);
		return;
	end
	
	-- Standard handling
	CombatRecordManager.addBattleHelper(tCustom);

	-- Open combat tracker
	Interface.openWindow("combattracker_host", "combattracker");
end
function addBattleHelper(tCustom)
	-- Cycle through the NPC list, and add them to the tracker
	for _, nodeBattleEntry in pairs(DB.getChildren(tCustom.nodeRecord, tCustom.sListPath)) do
		-- Get entry data
		local tBattleEntry = CombatRecordManager.getBattleEntryData(nodeBattleEntry);
		if tBattleEntry and tBattleEntry.nodeRecord then
			for i = 1, tBattleEntry.nCount do
				local t = UtilityManager.copyDeep(tBattleEntry);
				t.tPlacement = t.tAllPlacements[i];
				t.tBattleEntry = tBattleEntry;

				local sEntryRecordType = LibraryData.getRecordTypeFromRecordPath(t.sRecord);
				if CombatRecordManager.hasRecordTypeCallback(sEntryRecordType) then
					CombatRecordManager.onRecordTypeEvent(sEntryRecordType, t);
				end
				if not t.nodeCT then
					local s = string.format("%s (%s) (%s)", Interface.getString("ct_error_addnpcfail"), tBattleEntry.sName, tBattleEntry.sRecord);
					ChatManager.SystemMessage(s);
				end
			end
		else
			local s;
			if tBattleEntry then
				s = string.format("%s (%s) (%s)", Interface.getString("ct_error_addnpcfail2"), tBattleEntry.sName, tBattleEntry.sRecord);
			else
				s = Interface.getString("ct_error_addnpcfail2");
			end
			ChatManager.SystemMessage(s);
		end
	end
end
function getBattleEntryData(nodeBattleEntry)
	if not nodeBattleEntry then
		return nil;
	end

	local t = {};
	t.nodeBattleEntry = nodeBattleEntry;
	t.sClass, t.sRecord = DB.getValue(nodeBattleEntry, "link", "", "");
	t.sName = DB.getValue(nodeBattleEntry, "name", "");
	if t.sRecord ~= "" then
		t.nodeRecord = DB.findNode(t.sRecord);
	end

	t.nCount = DB.getValue(nodeBattleEntry, "count", 0);
	t.sFaction = DB.getValue(nodeBattleEntry, "faction", "");
	t.sToken = DB.getValue(nodeBattleEntry, "token", "");
	t.nIdentified = DB.getValue(nodeBattleEntry, "isidentified", 1);

	t.tAllPlacements = {};
	for _,nodePlacement in pairs(DB.getChildren(nodeBattleEntry, "maplink")) do
		local tPlacement = {};
		local _, sRecord = DB.getValue(nodePlacement, "imageref", "", "");
		tPlacement.imagelink = sRecord;
		tPlacement.imagex = DB.getValue(nodePlacement, "imagex", 0);
		tPlacement.imagey = DB.getValue(nodePlacement, "imagey", 0);
		table.insert(t.tAllPlacements, tPlacement);
	end

	return t;
end
function handleBattleModuleLoad(tCustom)
	local tRecordPaths = {};
	for _, nodeBattleEntry in pairs(DB.getChildren(tCustom.nodeRecord, tCustom.sListPath)) do
		local sClass, sRecord = DB.getValue(nodeBattleEntry, "link", "", "");
		if sRecord ~= "" then
			if not DB.findNode(sRecord) then
				table.insert(tRecordPaths, sRecord);
			end
		end
		local tImagePaths = {};
		for _,vPlacement in pairs(DB.getChildren(nodeBattleEntry, "maplink")) do
			local sClass, sRecord = DB.getValue(vPlacement, "imageref", "", "");
			if sRecord ~= "" then
				tImagePaths[sRecord] = true;
			end
		end
		for k, _ in pairs(tImagePaths) do
			if not DB.findNode(k) then
				table.insert(tRecordPaths, k);
			end
		end
	end
	return ModuleManager.handleRecordModulesLoad(tRecordPaths, CombatRecordManager.onBattleNPCLoadCallback, tCustom);
end
function onBattleNPCLoadCallback(tCustom)
	CombatRecordManager.addBattle(tCustom);
end
