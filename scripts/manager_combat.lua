-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_ENDTURN = "endturn";

CT_MAIN_PATH = "combattracker";
CT_COMBATANT_PATH = "combattracker.list.*";
CT_LIST = "combattracker.list";
CT_ROUND = "combattracker.round";

local sActiveCT = nil;

function onInit()
	Interface.onDesktopInit = onDesktopInit;
end
function onDesktopInit()
	OOBManager.registerOOBMsgHandler(CombatManager.OOB_MSGTYPE_ENDTURN, CombatManager.handleEndTurn);
	DB.addHandler(CombatManager.CT_COMBATANT_PATH, "onDelete", CombatManager.onDeleteCombatantEvent);
	DB.addHandler(DB.getPath(CombatManager.CT_COMBATANT_PATH, "effects"), "onChildAdded", CombatManager.onAddCombatantEffectEvent);
	DB.addHandler(DB.getPath(CombatManager.CT_COMBATANT_PATH, "effects"), "onChildDeleted", CombatManager.onDeleteCombatantEffectEvent);
	if Session.IsHost then
		DB.addHandler("charsheet.*", "onDelete", CombatManager.onCharDelete);
	end
end

local _bInitHotKey = false;
function registerStandardCombatHotKeys()
	if _bInitHotKey then
		return;
	end

	Interface.onHotkeyActivated = CombatManager.onHotKey;

	_bInitHotKey = true;
end
function onHotKey(draginfo)
	local sDragType = draginfo.getType();
	if sDragType == "combattrackernextactor" then
		if Session.IsHost then
			CombatManager.nextActor();
		else
			CombatManager.notifyEndTurn();
		end
		return true;
	elseif sDragType == "combattrackernextround" then
		if Session.IsHost then
			CombatManager.nextRound(1);
		end
		return true;
	end
end

--
-- COMBATANT HANDLERS
-- NOTE: Combatant list/count handler is single linked, combat event handlers are multi-linked, and field handlers are unmanaged (ruleset code must add/remove)
--

local fCustomGetCombatantNodes = nil;
function setCustomGetCombatantNodes(f)
	fCustomGetCombatantNodes = f;
end

local aCustomDeleteCombatantHandlers = {};
function setCustomDeleteCombatantHandler(f)
	table.insert(aCustomDeleteCombatantHandlers, f);
end
function removeCustomDeleteCombatantHandler(f)
	for kCustomDelete,fCustomDelete in ipairs(aCustomDeleteCombatantHandlers) do
		if fCustomDelete == f then
			table.remove(aCustomDeleteCombatantHandlers, kCustomDelete);
			return true;
		end
	end
	return false;
end
function onDeleteCombatantEvent(nodeCT)
	for _,fCustomDelete in ipairs(aCustomDeleteCombatantHandlers) do
		if fCustomDelete(nodeCT) then
			return true;
		end
	end
	return false;
end

local aCustomAddCombatantEffectHandlers = {};
function setCustomAddCombatantEffectHandler(f)
	table.insert(aCustomAddCombatantEffectHandlers, f);
end
function removeCustomAddCombatantEffectHandler(f)
	for kCustomAdd,fCustomAdd in ipairs(aCustomAddCombatantEffectHandlers) do
		if fCustomAdd == f then
			table.remove(aCustomAddCombatantEffectHandlers, kCustomAdd);
			return true;
		end
	end
	return false;
end
function onAddCombatantEffectEvent(nodeEffectList, nodeEffect)
	for _,fCustomAdd in ipairs(aCustomAddCombatantEffectHandlers) do
		if fCustomAdd(nodeEffectList.getParent(), nodeEffect) then
			return true;
		end
	end
	return false;
end

local aCustomDeleteCombatantEffectHandlers = {};
function setCustomDeleteCombatantEffectHandler(f)
	table.insert(aCustomDeleteCombatantEffectHandlers, f);
end
function removeCustomDeleteCombatantEffectHandler(f)
	for kCustomDelete,fCustomDelete in ipairs(aCustomDeleteCombatantEffectHandlers) do
		if fCustomDelete == f then
			table.remove(aCustomDeleteCombatantEffectHandlers, kCustomDelete);
			return true;
		end
	end
	return false;
end
function onDeleteCombatantEffectEvent(nodeEffectList)
	local nodeCT = DB.getChild(nodeEffectList, "..");
	for _,fCustomDelete in ipairs(aCustomDeleteCombatantEffectHandlers) do
		if fCustomDelete(nodeCT) then
			return true;
		end
	end
	return false;
end

function addCombatantFieldChangeHandler(sField, sEvent, f)
	DB.addHandler(DB.getPath(CombatManager.CT_COMBATANT_PATH, sField), sEvent, f);
end
function removeCombatantFieldChangeHandler(sField, sEvent, f)
	DB.removeHandler(DB.getPath(CombatManager.CT_COMBATANT_PATH, sField), sEvent, f);
end
function addCombatantEffectFieldChangeHandler(sField, sEvent, f)
	DB.addHandler(DB.getPath(CombatManager.CT_COMBATANT_PATH, "effects.*", sField), sEvent, f);
end
function removeCombatantEffectFieldChangeHandler(sField, sEvent, f)
	DB.removeHandler(DB.getPath(CombatManager.CT_COMBATANT_PATH, "effects.*", sField), sEvent, f);
end

--
-- MULTI HANDLERS
-- NOTE: Handlers added here will all be called in the order they were added.
--

local aCustomRoundStart = {};
function setCustomRoundStart(fRoundStart)
	table.insert(aCustomRoundStart, fRoundStart);
end
function onRoundStartEvent(nCurrent)
	if #aCustomRoundStart > 0 then
		for _,fCustomRoundStart in ipairs(aCustomRoundStart) do
			fCustomRoundStart(nCurrent);
		end
	end
end

local aCustomTurnStart = {};
function setCustomTurnStart(fTurnStart)
	table.insert(aCustomTurnStart, fTurnStart);
end
function onTurnStartEvent(nodeCT)
	if #aCustomTurnStart > 0 then
		for _,fCustomTurnStart in ipairs(aCustomTurnStart) do
			fCustomTurnStart(nodeCT);
		end
	end
end

local aCustomTurnEnd = {};
function setCustomTurnEnd(fTurnEnd)
	table.insert(aCustomTurnEnd, fTurnEnd);
end
function onTurnEndEvent(nodeCT)
	if #aCustomTurnEnd > 0 then
		for _,fCustomTurnEnd in ipairs(aCustomTurnEnd) do
			fCustomTurnEnd(nodeCT);
		end
	end
end

local aCustomInitChange = {};
function setCustomInitChange(fInitChange)
	table.insert(aCustomInitChange, fInitChange);
end
function onInitChangeEvent(nodeOldCT, nodeNewCT)
	if #aCustomInitChange > 0 then
		for _,fCustomInitChange in ipairs(aCustomInitChange) do
			fCustomInitChange(nodeOldCT, nodeNewCT);
		end
	end
end

local aCustomCombatReset = {};
function setCustomCombatReset(fCombatReset)
	table.insert(aCustomCombatReset, fCombatReset);
end
function onCombatResetEvent()
	if #aCustomCombatReset > 0 then
		for _,fCustomCombatReset in ipairs(aCustomCombatReset) do
			fCustomCombatReset();
		end
	end
end

--
-- SINGLE HANDLERS
-- NOTE: Setting these handlers will override previous handlers
--

local fCustomSort = nil;
function setCustomSort(fSort)
	fCustomSort = fSort;
end
function getCustomSort()
	return fCustomSort;
end
-- NOTE: Lua sort function expects the opposite boolean value compared to built-in FG sorting
function onSortCompare(node1, node2)
	if fCustomSort then
		return not fCustomSort(node1, node2);
	end
	
	return not CombatManager.sortfuncSimple(node1, node2);
end

--
-- GENERAL
--

function createCombatantNode()
	DB.createNode(CombatManager.CT_LIST);
	return DB.createChild(CombatManager.CT_LIST);
end

function getCombatantNodes()
	if fCustomGetCombatantNodes then
		return fCustomGetCombatantNodes();
	end
	return DB.getChildren(CombatManager.CT_LIST);
end

function getActiveCT()
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		if DB.getValue(v, "active", 0) == 1 then
			return v;
		end
	end
	return nil;
end

function getCTFromNode(varNode)
	-- Get path name desired
	local sNode;
	if type(varNode) == "string" then
		sNode = varNode;
	elseif type(varNode) == "databasenode" then
		sNode = varNode.getPath();
	else
		return nil;
	end
	
	local tCombatantList = CombatManager.getCombatantNodes();

	-- Check for exact CT match
	for _,v in pairs(tCombatantList) do
		if v.getPath() == sNode then
			return v;
		end
	end

	-- Otherwise, check for link match
	for _,v in pairs(tCombatantList) do
		local sClass, sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sNode then
			return v;
		end
	end

	return nil;
end

function getCTFromTokenRef(vContainer, nId)
	local sContainerNode = nil;
	if type(vContainer) == "string" then
		sContainerNode = vContainer;
	elseif type(vContainer) == "databasenode" then
		sContainerNode = vContainer.getPath();
	else
		return nil;
	end
	
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		local sCTContainerName = DB.getValue(v, "tokenrefnode", "");
		local nCTId = tonumber(DB.getValue(v, "tokenrefid", "")) or 0;
		if (sCTContainerName == sContainerNode) and (nCTId == nId) then
			return v;
		end
	end
	
	return nil;
end

function getCTFromToken(token)
	if not token then
		return nil;
	end
	
	local nodeContainer = token.getContainerNode();
	local nID = token.getId();

	return CombatManager.getCTFromTokenRef(nodeContainer, nID);
end

function getTokenFromCT(vEntry)
	local nodeCT = nil;
	if type(vEntry) == "string" then
		nodeCT = DB.findNode(vEntry);
	elseif type(vEntry) == "databasenode" then
		nodeCT = vEntry;
	end
	if not nodeCT then
		return nil;
	end
	
	return Token.getToken(DB.getValue(nodeCT, "tokenrefnode", ""), DB.getValue(nodeCT, "tokenrefid", ""));
end

function getCurrentUserCT()
	if Session.IsHost then
		return CombatManager.getActiveCT();
	end
	
	-- If active identity is owned, then use that one
	local nodeActive = CombatManager.getActiveCT();
	local sClass, sRecord = DB.getValue(nodeActive, "link", "npc", "");
	if sClass == "charsheet" then
		local aOwned = User.getOwnedIdentities();
		for _,v in ipairs(aOwned) do
			if sRecord == ("charsheet." .. v) then
				return nodeActive;
			end
		end
	end
	
	-- Otherwise, use active identity (if any)
	local sID = User.getCurrentIdentity();
	if sID then
		return CombatManager.getCTFromNode("charsheet." .. sID);
	end

	return nil;
end

function openMap(vNode)
	local nodeCT = CombatManager.getCTFromNode(vNode);
	if not nodeCT then 
		return; 
	end
	CombatManager.centerOnToken(nodeCT, true);
end

function isCTHidden(vEntry)
	local nodeCT = nil;
	if type(vEntry) == "string" then
		nodeCT = DB.findNode(vEntry);
	elseif type(vEntry) == "databasenode" then
		nodeCT = vEntry;
	end
	if not nodeCT then
		return false;
	end
	
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		return false;
	end
	if DB.getValue(nodeCT, "tokenvis", 0) == 1 then
		return false;
	end
	return true;
end

function onCharDelete(nodeChar)
	if not Session.IsHost then
		return;
	end

	local nodeCT = CombatManager.getCTFromNode(nodeChar);
	if nodeCT then
		DB.setValue(nodeCT, "link", "windowreference", "npc", "");
	end
end

function onTokenDelete(tokenMap)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		DB.setValue(nodeCT, "tokenrefnode", "string", "");
		DB.setValue(nodeCT, "tokenrefid", "string", "");
	end
end

--
-- COMBAT TRACKER SORT
--
-- NOTE: Lua sort function expects the opposite boolean value compared to built-in FG sorting
--

function sortfuncSimple(node1, node2)
	return node1.getPath() < node2.getPath();
end

function sortfuncStandard(node1, node2)
	local bHost = Session.IsHost;
	local sOptCTSI = OptionsManager.getOption("CTSI");
	
	local sFaction1 = DB.getValue(node1, "friendfoe", "");
	local sFaction2 = DB.getValue(node2, "friendfoe", "");
	
	local bShowInit1 = bHost or ((sOptCTSI == "friend") and (sFaction1 == "friend")) or (sOptCTSI == "on");
	local bShowInit2 = bHost or ((sOptCTSI == "friend") and (sFaction2 == "friend")) or (sOptCTSI == "on");
	
	if bShowInit1 ~= bShowInit2 then
		if bShowInit1 then
			return true;
		elseif bShowInit2 then
			return false;
		end
	else
		if bShowInit1 then
			local nValue1 = DB.getValue(node1, "initresult", 0);
			local nValue2 = DB.getValue(node2, "initresult", 0);
			if nValue1 ~= nValue2 then
				return nValue1 > nValue2;
			end
		else
			if sFaction1 ~= sFaction2 then
				if sFaction1 == "friend" then
					return true;
				elseif sFaction2 == "friend" then
					return false;
				end
			end
		end
	end
	
	local sValue1 = DB.getValue(node1, "name", "");
	local sValue2 = DB.getValue(node2, "name", "");
	if sValue1 ~= sValue2 then
		return sValue1 < sValue2;
	end

	return node1.getPath() < node2.getPath();
end

function sortfuncDnD(node1, node2)
	local bHost = Session.IsHost;
	local sOptCTSI = OptionsManager.getOption("CTSI");
	
	local sFaction1 = DB.getValue(node1, "friendfoe", "");
	local sFaction2 = DB.getValue(node2, "friendfoe", "");
	
	local bShowInit1 = bHost or ((sOptCTSI == "friend") and (sFaction1 == "friend")) or (sOptCTSI == "on");
	local bShowInit2 = bHost or ((sOptCTSI == "friend") and (sFaction2 == "friend")) or (sOptCTSI == "on");
	
	if bShowInit1 ~= bShowInit2 then
		if bShowInit1 then
			return true;
		elseif bShowInit2 then
			return false;
		end
	else
		if bShowInit1 then
			local nValue1 = DB.getValue(node1, "initresult", 0);
			local nValue2 = DB.getValue(node2, "initresult", 0);
			if nValue1 ~= nValue2 then
				return nValue1 > nValue2;
			end
			
			nValue1 = DB.getValue(node1, "init", 0);
			nValue2 = DB.getValue(node2, "init", 0);
			if nValue1 ~= nValue2 then
				return nValue1 > nValue2;
			end
		else
			if sFaction1 ~= sFaction2 then
				if sFaction1 == "friend" then
					return true;
				elseif sFaction2 == "friend" then
					return false;
				end
			end
		end
	end
	
	local sValue1 = DB.getValue(node1, "name", "");
	local sValue2 = DB.getValue(node2, "name", "");
	if sValue1 ~= sValue2 then
		return sValue1 < sValue2;
	end

	return node1.getPath() < node2.getPath();
end

function getSortedCombatantList()
	local aEntries = {};
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		table.insert(aEntries, v);
	end
	if #aEntries > 0 then
		if fCustomSort then
			table.sort(aEntries, fCustomSort);
		else
			table.sort(aEntries, sortfuncSimple);
		end
	end
	return aEntries;
end

--
-- TURN FUNCTIONS
--

function handleEndTurn(msgOOB)
	local rActor = ActorManager.resolveActor(getActiveCT());
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if nodeActor and nodeActor.getOwner() == msgOOB.user then
		CombatManager.nextActor();
	end
end

function notifyEndTurn()
	local msgOOB = {};
	msgOOB.type = CombatManager.OOB_MSGTYPE_ENDTURN;
	msgOOB.user = User.getUsername();

	Comm.deliverOOBMessage(msgOOB, "");
end

function addGMIdentity(nodeEntry)
	if OptionsManager.isOption("CTAV", "on") then
		local sName = ActorManager.getDisplayName(nodeEntry);
		local sClass,_ = DB.getValue(nodeEntry, "link", "", "");
		
		if sClass == "charsheet" or sName == "" then
			sActiveCT = nil;
			GmIdentityManager.activateGMIdentity();
		else
			if GmIdentityManager.existsIdentity(sName) then
				sActiveCT = nil;
				GmIdentityManager.setCurrent(sName);
			else
				sActiveCT = sName;
				GmIdentityManager.addIdentity(sName);
			end
		end
	end
end

function clearGMIdentity()
	if sActiveCT then
		GmIdentityManager.removeIdentity(sActiveCT);
		sActiveCT = nil;
	end
end

-- Handle turn notification (including bell ring based on option)
function showTurnMessage(nodeEntry, bActivate, bSkipBell)
	if not Session.IsHost then
		return;
	end

	local rActor = ActorManager.resolveActor(nodeEntry);
	local sName = ActorManager.getDisplayName(rActor);
	local sFaction = ActorManager.getFaction(rActor);

	local msgGM = {font = "narratorfont", icon = "turn_flag"};
	msgGM.text = string.format("[%s] %s", Interface.getString("combat_tag_turn"), sName);

	local msgPlayer = {font = "narratorfont", icon = "turn_flag"};
	msgPlayer.text = msgGM.text;

	if OptionsManager.isOption("RSHE", "on") then
		if sFaction == "friend" then
			local sEffects = EffectManager.getEffectsString(nodeEntry, true);
			if sEffects ~= "" then
				msgPlayer.text = msgPlayer.text .. " - [" .. sEffects .. "]";
			end
		end
		local sEffectsGM = EffectManager.getEffectsString(nodeEntry, false);
		if sEffectsGM ~= "" then
			msgGM.text = msgGM.text .. " - [" .. sEffectsGM .. "]";
		end
	end

	local sOptRSHT = OptionsManager.getOption("RSHT");
	local bShowPlayerMessage = bActivate and ((sOptRSHT == "all") or ((sOptRSHT == "on") and (sFaction == "friend")));

	msgGM.secret = not bShowPlayerMessage;
	Comm.addChatMessage(msgGM);

	if bShowPlayerMessage and not CombatManager.isCTHidden(nodeEntry) then
		local aUsers = User.getActiveUsers();
		if #aUsers > 0 then
			Comm.deliverChatMessage(msgPlayer, aUsers);
		end

		if not bSkipBell and ActorManager.isPC(rActor) and OptionsManager.isOption("RING", "on") then
			local nodePC = ActorManager.getCreatureNode(rActor);
			if nodePC then
				local sOwner = nodePC.getOwner();
				if sOwner then
					User.ringBell(sOwner);
				end
			end
		end
	end
end

function requestActivation(nodeEntry, bSkipBell)
	-- De-activate all other entries
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		DB.setValue(v, "active", "number", 0);
	end
	
	-- Set active flag
	DB.setValue(nodeEntry, "active", "number", 1);

	-- Turn notification
	CombatManager.showTurnMessage(nodeEntry, true, bSkipBell);

	-- Handle GM identity list updates (based on option)
	CombatManager.clearGMIdentity();
	CombatManager.addGMIdentity(nodeEntry);
end

function centerOnToken(nodeEntry, bOpen)
	if not Session.IsHost then
		local sClass, sRecord = DB.getValue(nodeEntry, "link", "", "");
		if sClass ~= "charsheet" then 
			return; 
		end
		local bOwned = DB.isOwner(sRecord);
		if not bOwned then 
			return; 
		end
	end
	ImageManager.centerOnToken(getTokenFromCT(nodeEntry), bOpen);
end

function isActorToSkipTurn(nodeEntry)
	local rActor = ActorManager.resolveActor(nodeEntry);
	if EffectManager.hasEffect(rActor, "SKIPTURN") then
		return true;
	end

	local sFaction = ActorManager.getFaction(rActor);
	if sFaction == "friend" then
		return false;
	else
		local bSkipDeadEnemy = OptionsManager.isOption("CTSD", "on");
		if bSkipDeadEnemy then
			if ActorHealthManager.isDyingOrDead(rActor) then
				return true;
			end
		end
	end

	local bSkipHidden = OptionsManager.isOption("CTSH", "on");
	if bSkipHidden and CombatManager.isCTHidden(nodeEntry) then
		return true;
	end

	return false;
end

function nextActor(bSkipBell, bNoRoundAdvance)
	if not Session.IsHost then
		return;
	end

	local aEntries = CombatManager.getSortedCombatantList();

	local nodeActive = CombatManager.getActiveCT();
	local nIndexActive = 0;
	
	local nodeNext = nil;
	local nIndexNext = 0;

	-- Determine the next actor
	if #aEntries > 0 then
		if nodeActive then
			for i = 1,#aEntries do
				if aEntries[i] == nodeActive then
					nIndexActive = i;
					break;
				end
			end
		end
		for i = nIndexActive + 1, #aEntries do
			if not CombatManager.isActorToSkipTurn(aEntries[i]) then
				nIndexNext = i;
				break;
			end
		end
		if nIndexNext > nIndexActive then
			nodeNext = aEntries[nIndexNext];
			for i = nIndexActive + 1, nIndexNext - 1 do
				CombatManager.showTurnMessage(aEntries[i], false);
			end
		end
	end

	-- If next actor available, advance effects, activate and start turn
	if nodeNext then
		-- End turn for current actor
		if nodeActive then
			CombatManager.onTurnEndEvent(nodeActive);
		end
	
		-- Process effects in between current and next actors
		if nodeActive then
			CombatManager.onInitChangeEvent(nodeActive, nodeNext);
		else
			CombatManager.onInitChangeEvent(nil, nodeNext);
		end
		
		-- Start turn for next actor
		CombatManager.requestActivation(nodeNext, bSkipBell);
		CombatManager.onTurnStartEvent(nodeNext);
	elseif not bNoRoundAdvance then
		for i = nIndexActive + 1, #aEntries do
			CombatManager.showTurnMessage(aEntries[i], false);
		end
		CombatManager.nextRound(1);
	end
end

function nextRound(nRounds)
	if not Session.IsHost then
		return;
	end

	local nodeActive = CombatManager.getActiveCT();
	local nCurrent = DB.getValue(CombatManager.CT_ROUND, 0);

	-- If current actor, then advance based on that
	local nStartCounter = 1;
	local aEntries = CombatManager.getSortedCombatantList();
	if nodeActive then
		DB.setValue(nodeActive, "active", "number", 0);
		CombatManager.clearGMIdentity();

		local bFastTurn = false;
		for i = 1,#aEntries do
			if aEntries[i] == nodeActive then
				bFastTurn = true;
				CombatManager.onTurnEndEvent(nodeActive);
			elseif bFastTurn then
				CombatManager.onTurnStartEvent(aEntries[i]);
				CombatManager.onTurnEndEvent(aEntries[i]);
			end
		end
		
		CombatManager.onInitChangeEvent(nodeActive);

		nStartCounter = nStartCounter + 1;

		-- Announce round
		nCurrent = nCurrent + 1;
		local msg = {font = "narratorfont", icon = "turn_flag"};
		msg.text = "[" .. Interface.getString("combat_tag_round") .. " " .. nCurrent .. "]";
		Comm.deliverChatMessage(msg);
	end
	for i = nStartCounter, nRounds do
		for i = 1,#aEntries do
			CombatManager.onTurnStartEvent(aEntries[i]);
			CombatManager.onTurnEndEvent(aEntries[i]);
		end
		
		CombatManager.onInitChangeEvent();
		
		-- Announce round
		nCurrent = nCurrent + 1;
		local msg = {font = "narratorfont", icon = "turn_flag"};
		msg.text = "[" .. Interface.getString("combat_tag_round") .. " " .. nCurrent .. "]";
		Comm.deliverChatMessage(msg);
	end

	-- Update round counter
	DB.setValue(CombatManager.CT_ROUND, "number", nCurrent);
	
	-- Custom round start callback (such as per round initiative rolling)
	CombatManager.onRoundStartEvent(nCurrent);
	
	-- Check option to see if we should advance to first actor or stop on round start
	if OptionsManager.isOption("RNDS", "off") then
		local bSkipBell = (nRounds > 1);
		if #aEntries > 0 then
			CombatManager.nextActor(bSkipBell, true);
		end
	end
end

--
-- ADD FUNCTIONS
--

function stripCreatureNumber(s)
	local nStarts, _, sNumber = string.find(s, " ?(%d+)$");
	if nStarts then
		return string.sub(s, 1, nStarts - 1), sNumber;
	end
	return s;
end
function randomName(sBaseName)
	local aNames = {};
	local nCombatantCount = 0;
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		local sName = DB.getValue(v, "name", "");
		if sName ~= "" then
			table.insert(aNames, DB.getValue(v, "name", ""));
		end
		nCombatantCount = nCombatantCount + 1;
	end
	
	local nRandomRange = nCombatantCount * 2;
	local sNewName = sBaseName;
	local nSuffix;
	local bContinue = true;
	while bContinue do
		bContinue = false;
		nSuffix = math.random(nRandomRange);
		sNewName = sBaseName .. " " .. nSuffix;
		if StringManager.contains(aNames, sNewName) then
			bContinue = true;
		end
	end

	return sNewName, nSuffix;
end

--
-- RESET FUNCTIONS
--

function resetInit()
	-- De-activate all entries
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		DB.setValue(v, "active", "number", 0);
	end
	
	-- Clear GM identity additions (based on option)
	CombatManager.clearGMIdentity();

	-- Reset the round counter
	DB.setValue(CombatManager.CT_ROUND, "number", 1);
	
	CombatManager.onCombatResetEvent();
end

function resetCombatantEffects()
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		DB.deleteChildren(v, "effects");
	end
end

--
-- GENERAL ITERATION FUNCTIONS
--

function callForEachCombatant(f, ...)
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		f(v, ...);
	end
end

function callForEachCombatantEffect(f, ...)
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		EffectManager.startDelayedUpdates();
		for _,nodeEffect in pairs(DB.getChildren(v, "effects")) do
			f(nodeEffect, ...);
		end
		EffectManager.endDelayedUpdates();
	end
end

--
-- COMMON RULESET SPECIFIC FUNCTIONS
--

function rollTypeInit(sType, fRollCombatantEntryInit, ...)
	local tCombatantNodesToRoll = {};

	for _,v in pairs(CombatManager.getCombatantNodes()) do
		local bRoll = true;
		if sType then
			local rActor = ActorManager.resolveActor(v);
			if sType == "pc" then
				if not ActorManager.isPC(rActor) then
					bRoll = false;
				end
			elseif not ActorManager.isRecordType(rActor, sType) then
				bRoll = false;
			end
		end
		if bRoll then
			table.insert(tCombatantNodesToRoll, v);
		end
	end

	for _,v in ipairs(tCombatantNodesToRoll) do
		DB.setValue(v, "initresult", "number", -10000);
	end

	for _,v in ipairs(tCombatantNodesToRoll) do
		fRollCombatantEntryInit(v, ...);
	end
end

--
-- COMBAT TRACKER SUPPORT
--

function handleFactionDropOnImage(draginfo, imagecontrol, x, y)
	if not Session.IsHost then return; end

	local nVersionMajor, nVersionMinor = Interface.getVersion();
	local bUseOldAPIMethod = ((nVersionMajor < 4) or (nVersionMinor < 2));

	-- Snap drop point and adjust drop spread to grid size
	x, y = imagecontrol.snapToGrid(x, y);

	-- Calculate drop spread
	local nDropSpread;
	if bUseOldAPIMethod then
		nDropSpread = imagecontrol.getGridSize() / Interface.getUIScale();
	else
		nDropSpread = imagecontrol.getGridSize();
	end

	-- Grab faction data from drag object, and apply to each combatant node
	local sFaction = draginfo.getStringData();
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		if DB.getValue(v, "friendfoe", "") == sFaction then
			local sToken = DB.getValue(v, "token", "");
			if sToken ~= "" then
				-- Add it to the image at the drop coordinates
				TokenManager.setDragTokenUnits(DB.getValue(v, "space"));
				local tokenMap = imagecontrol.addToken(sToken, x, y);
				TokenManager.endDragTokenWithUnits();

				-- Update token references
				CombatManager.replaceCombatantToken(v, tokenMap);
				
				-- Offset drop coordinates for next token
				x = x - nDropSpread;
				y = y - nDropSpread;
			end
		end
	end
	
	return true;
end

function replaceCombatantToken(nodeCT, newTokenInstance)
	local oldTokenInstance = CombatManager.getTokenFromCT(nodeCT);
	if oldTokenInstance and oldTokenInstance ~= newTokenInstance then
		if not newTokenInstance then
			local nodeContainerOld = oldTokenInstance.getContainerNode();
			if nodeContainerOld then
				local x,y = oldTokenInstance.getPosition();
				TokenManager.setDragTokenUnits(DB.getValue(nodeCT, "space"));
				newTokenInstance = Token.addToken(nodeContainerOld.getPath(), DB.getValue(nodeCT, "token", ""), x, y);
				TokenManager.endDragTokenWithUnits();
			end
		end
		oldTokenInstance.delete();
	end

	TokenManager.linkToken(nodeCT, newTokenInstance);
	TokenManager.updateVisibility(nodeCT);
	TargetingManager.updateTargetsFromCT(nodeCT, newTokenInstance);
end

--
-- DEPRECATED
--

function setCustomDrop(fn)
	CombatDropManager.registerLegacyDropCallback(fn);
end
function onDropEvent(rSource, rTarget, draginfo)
	CombatDropManager.onLegacyDropEvent(rSource, rTarget, draginfo);
end

function onDrop(sNodeType, sNodePath, draginfo)
	return CombatDropManager.handleAnyDrop(draginfo, sNodePath);
end

local fCustomAddPC = nil;
function setCustomAddPC(fAddPC)
	fCustomAddPC = fAddPC;
end
function getCustomAddPC()
	return fCustomAddPC;
end
local fCustomAddNPC = nil;
function setCustomAddNPC(fAddNPC)
	fCustomAddNPC = fAddNPC;
end
function getCustomAddNPC()
	return fCustomAddNPC;
end
local fCustomAddBattle = nil;
function setCustomAddBattle(fAddBattle)
	fCustomAddBattle = fAddBattle;
end
function getCustomAddBattle()
	return fCustomAddBattle;
end
local fCustomNPCSpaceReach = nil;
function setCustomNPCSpaceReach(fNPCSpaceReach)
	fCustomNPCSpaceReach = fNPCSpaceReach;
end
function getCustomNPCSpaceReach()
	return fCustomNPCSpaceReach;
end

function addPC(nodePC)
	Debug.console("CombatManager.addPC - DEPRECATED - 2022-08-16 - Use CombatRecordManager.setRecordTypePostAddCallback/setRecordTypeCallback(\"charsheet\", fn).");
	CombatRecordManager.addPC({ sRecordType = "charsheet", nodeRecord = nodePC });
end
function addBattle(nodeBattle)
	Debug.console("CombatManager.addBattle - DEPRECATED - 2022-08-16 - Use CombatRecordManager.setRecordTypePostAddCallback/setRecordTypeCallback(\"battle\", fn).");
	CombatRecordManager.addBattle({ sRecordType = "battle", nodeRecord = nodeBattle });
end
function addNPC(sClass, nodeNPC, sName)
	Debug.console("CombatManager.addNPC - DEPRECATED - 2022-08-16 - Use CombatRecordManager.setRecordTypePostAddCallback/setRecordTypeCallback(\"npc\", fn).");
	local tCustom = { sRecordType = "npc", nodeRecord = nodeNPC, sClass = sClass, sName = sName };
	CombatRecordManager.addNPC(tCustom);
	return tCustom.nodeCT;
end
function addNPCHelper(nodeSource, sName, sClass)
	Debug.console("CombatManager.addNPCHelper - DEPRECATED - 2022-08-16 - Use CombatRecordManager.setRecordTypePostAddCallback/setRecordTypeCallback(\"npc\", fn).");
	local tCustom = { sRecordType = "npc", nodeRecord = nodeSource, sClass = sClass, sName = sName };
	CombatRecordManager.addNPCHelper(tCustom);
	return tCustom.nodeCT, tCustom.nodeCTLastMatch;
end
function getNPCSpaceReach(nodeNPC)
	Debug.console("CombatManager.getNPCSpaceReach - DEPRECATED - 2022-08-16 - ActorCommonManager.getSpaceReach.");
	return ActorCommonManager.getSpaceReach(nodeNPC);
end
