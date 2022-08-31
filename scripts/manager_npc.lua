-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	Interface.onDesktopInit = onDesktopInit;
end
function onDesktopInit()
	if Session.IsHost then
		DB.addHandler(DB.getPath(CombatManager.CT_COMBATANT_PATH, "isidentified"), "onUpdate", NPCManager.onCTEntryIDUpdate);
	end
end

local bProcessingCTEntryIDUpdate = false;
function onCTEntryIDUpdate(vNode)
	if bProcessingCTEntryIDUpdate then return; end
	bProcessingCTEntryIDUpdate = true;
	
	local nodeCT = vNode.getParent();
	local nIsIdentified = DB.getValue(nodeCT, "isidentified", 1);
	local _,sCTEntrySourceRecord = DB.getValue(nodeCT, "sourcelink", "", "");
	if sCTEntrySourceRecord ~= "" then
		for _,v in pairs(CombatManager.getCombatantNodes()) do
			local _,sRecord = DB.getValue(v, "sourcelink", "", "");
			if (sRecord == sCTEntrySourceRecord) and (v ~= nodeCT) then
				DB.setValue(v, "isidentified", "number", nIsIdentified);
			end
		end
	end

	bProcessingCTEntryIDUpdate = false;
end

function addLinkToBattle(nodeBattle, sLinkClass, sLinkRecord, nMult)
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";

	if (sLinkClass == "battle") or (sLinkClass == "battlerandom") then
		local tDelete = {};
		local nodeTargetNPCList = DB.createChild(nodeBattle, sTargetNPCList);
		for _,nodeSrcNPC in pairs(DB.getChildren(DB.getPath(sLinkRecord, sTargetNPCList))) do
			local nodeTargetNPC = DB.createChild(nodeTargetNPCList);
			DB.copyNode(nodeSrcNPC, nodeTargetNPC);
			if sLinkClass == "battlerandom" then
				local nCount = CampaignDataManager.convertRndEncExprToEncCount(nodeTargetNPC);
				if nCount <= 0 then
					table.insert(tDelete, nodeTargetNPC);
				end
			end
			if nMult then
				DB.setValue(nodeTargetNPC, "count", "number", DB.getValue(nodeTargetNPC, "count", 1) * nMult);
			end
		end
		for _,nodeDelete in ipairs(tDelete) do
			nodeDelete.delete();
		end
	else
		local sSourceType = LibraryData.getRecordTypeFromRecordPath(sLinkRecord);
		local aCombatClasses = LibraryData.getCustomData("battle", "acceptdrop") or { "npc" };
		if not StringManager.contains(aCombatClasses, sSourceType) then
			ChatManager.SystemMessage(Interface.getString("battle_message_wrong_source"));
			return false;
		end

		local sName = DB.getValue(DB.getPath(sLinkRecord, "name"), "");

		local nodeTargetNPCList = DB.createChild(nodeBattle, sTargetNPCList);
		local nodeTargetNPC = DB.createChild(nodeTargetNPCList);
		DB.setValue(nodeTargetNPC, "count", "number", nMult or 1);
		DB.setValue(nodeTargetNPC, "name", "string", sName);
		DB.setValue(nodeTargetNPC, "link", "windowreference", sLinkClass, sLinkRecord);
		
		local nodeID = DB.getChild(sLinkRecord, "isidentified");
		if nodeID then
			DB.setValue(nodeTargetNPC, "isidentified", "number", nodeID.getValue());
		end
		
		local sToken = DB.getValue(DB.getPath(sLinkRecord, "token"), "");
		if sToken == "" or not Interface.isToken(sToken) then
			local sLetter = StringManager.trim(sName):match("^([a-zA-Z])");
			if sLetter then
				sToken = "tokens/Medium/" .. sLetter:lower() .. ".png@Letter Tokens";
			else
				sToken = "tokens/Medium/z.png@Letter Tokens";
			end
		end
		DB.setValue(nodeTargetNPC, "token", "token", sToken);
	end
	
	return true;
end

function getNPCSourceType(vNode)
	Debug.console("NPCManager.getNPCSourceType - DEPRECATED - 2022-07-12 - Use LibraryData.getRecordTypeFromRecordPath");
	ChatManager.SystemMessage("NPCManager.getNPCSourceType - DEPRECATED - 2022-07-12 - Use LibraryData.getRecordTypeFromRecordPath");
	return LibraryData.getRecordTypeFromRecordPath(vNode);
end
