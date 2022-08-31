-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_WHISPER = "whisper";

--
-- INITIALIZATION
--

function onInit()
	ChatManager.addStandardWhisperSupport();
	ChatManager.addStandardModSupport();
	ChatManager.addStandardImportExportSupport();

	Interface.onDesktopInit = onDesktopInit;
end
function onDesktopInit()
	Module.onUnloadedReference = ChatManager.moduleUnloadedReference;
end
function addStandardWhisperSupport()
	if Session.IsHost then
		Comm.registerSlashHandler("w", ChatManager.processWhisper, "[charactername] [message]");
	else
		Comm.registerSlashHandler("w", ChatManager.processWhisper, "[charactername|GM] [message]");
	end
	Comm.registerSlashHandler("r", ChatManager.processReply, "[message]");
	OOBManager.registerOOBMsgHandler(ChatManager.OOB_MSGTYPE_WHISPER, ChatManager.handleWhisper);
end
function addStandardModSupport()
	Comm.registerSlashHandler("mod", ChatManager.processMod, "[number] <message>");
end
function addStandardImportExportSupport()
	Comm.registerSlashHandler("exportchar", ChatManager.processExportPC);
	if Session.IsHost then
		Comm.registerSlashHandler("exportnpc", ChatManager.processExportNPC);
		Comm.registerSlashHandler("flushdb", ChatManager.processFlush);
		Comm.registerSlashHandler("importchar", ChatManager.processImportPC);
		Comm.registerSlashHandler("importnpc", ChatManager.processImportNPC);
	end
end

--
-- HELPERS
--

function getChatWindow()
	return Interface.findWindow("chat", "");
end

--
-- EVENTS
--

local _tDiceLandedCallbacks = {};
local _tDeliverMessageCallbacks = {};
local _tReceiveMessageCallbacks = {};

local _tDropCallbacks = {};

function registerDiceLandedCallback(fn)
	UtilityManager.registerCallback(_tDiceLandedCallbacks, fn);
end
function unregisterDiceLandedCallback(fn)
	UtilityManager.unregisterCallback(_tDiceLandedCallbacks, fn);
end
function onDiceLanded(...)
	return UtilityManager.performCallbacks(_tDiceLandedCallbacks, ...);
end

function registerDeliverMessageCallback(fn)
	UtilityManager.registerCallback(_tDeliverMessageCallbacks, fn);
end
function unregisterDeliverMessageCallback(fn)
	UtilityManager.unregisterCallback(_tDeliverMessageCallbacks, fn);
end
function onDeliverMessage(...)
	return UtilityManager.performCallbacks(_tDeliverMessageCallbacks, ...);
end

function registerReceiveMessageCallback(fn)
	UtilityManager.registerCallback(_tReceiveMessageCallbacks, fn);
end
function unregisterReceiveMessageCallback(fn)
	UtilityManager.unregisterCallback(_tReceiveMessageCallbacks, fn);
end
function onReceiveMessage(...)
	return UtilityManager.performCallbacks(_tReceiveMessageCallbacks, ...);
end

function registerDropCallback(sDropType, fn)
	UtilityManager.registerKeyCallback(_tDropCallbacks, sDropType, fn);
end
function unregisterDropCallback(sDropType, fn)
	UtilityManager.unregisterKeyCallback(_tDropCallbacks, sDropType, fn);
end
function onDrop(draginfo)
	return UtilityManager.performKeyCallbacks(_tDropCallbacks, draginfo.getType(), draginfo);
end

function registerSlashCommand(sCommand, fCallback, vParamHelp)
	Debug.console("ChatManager.registerSlashCommand - DEPRECATED - 2022-07-12 - Use Comm.registerSlashHandler");
	Comm.registerSlashHandler(sCommand, fCallback, vParamHelp);
end
function unregisterSlashCommand(sCommand)
	Debug.console("ChatManager.unregisterSlashCommand - DEPRECATED - 2022-07-12 - Use Comm.registerSlashHandler");
	Comm.registerSlashHandler(sCommand, nil);
end
function onSlashCommand(sCommand, sParams)
	Debug.console("ChatManager.onSlashCommand - DEPRECATED - 2022-07-12 - No longer used");
end

--
-- MODULE NOTIFICATIONS
--

function moduleUnloadedReference(sModule, sClass, sPath)
	ModuleManager.handleRecordModulesLoad({ sPath }, ChatManager.onReferenceLoadCallback, { sClass = sClass, sPath = sPath });
end
function onReferenceLoadCallback(tCustom)
	Interface.openWindow(tCustom.sClass, tCustom.sPath);
end

--
-- AUTO-COMPLETE
--

function searchForIdentity(sSearch)
	for _,sIdentity in ipairs(User.getAllActiveIdentities()) do
		local sLabel = User.getIdentityLabel(sIdentity);
		if string.find(string.lower(sLabel), string.lower(sSearch), 1, true) == 1 then
			if User.getIdentityOwner(sIdentity) then
				return sIdentity;
			end
		end
	end

	return nil;
end
function doUserAutoComplete(ctrl)
	local buffer = ctrl.getValue();
	if buffer == "" then 
		return ;
	end

	-- Parse the string, adding one chunk at a time, looking for the maximum possible match
	local sReplacement = nil;
	local nStart = 2;
	while not sReplacement do
		local nSpace = string.find(string.reverse(buffer), " ", nStart, true);

		if nSpace then
			local sSearch = string.sub(buffer, #buffer - nSpace + 2);

			if not string.match(sSearch, "^%s$") then
				local sIdentity = ChatManager.searchForIdentity(sSearch);
				if sIdentity then
					local sRemainder = string.sub(buffer, 1, #buffer - nSpace + 1);
					sReplacement = sRemainder .. User.getIdentityLabel(sIdentity) .. " ";
					break;
				end
			end
		else
			local sIdentity = ChatManager.searchForIdentity(buffer);
			if sIdentity then
				sReplacement = User.getIdentityLabel(sIdentity) .. " ";
				break;
			end
			
			return;
		end

		nStart = nSpace + 1;
	end

	if sReplacement then
		ctrl.setValue(sReplacement);
		ctrl.setCursorPosition(#sReplacement + 1);
		ctrl.setSelectionPosition(#sReplacement + 1);
	end
end

--
-- DICE AND MOD SLASH HANDLERS
--

function processMod(sCommand, sParams)
	local sMod, sDesc = string.match(sParams, "%s*(%S+)%s*(.*)");
	
	local nMod = tonumber(sMod);
	if not nMod then
		ChatManager.SystemMessage("Usage: /mod [number] [description]");
		return;
	end
	
	ModifierStack.addSlot(sDesc, nMod);
end
function processFlush(sCommand, sParams)
	local nodeRoot = DB.findNode("");
	
	nodeRoot.removeAllHolders(true);
	nodeRoot.setPublic(false);
	Desktop.registerPublicNodes();
	
	ChatManager.SystemMessage(Interface.getString("message_slashflushsuccess"));
end

function processImportPC(sCommand, sParams)
	CampaignDataManager.importChar();
end
function processImportNPC(sCommand, sParams)
	CampaignDataManager.importNPC();
end
function processExportPC(sCommand, sParams)
	local nodeChar = nil;
	
	local sFind = StringManager.trim(sParams);
	if string.len(sFind) > 0 then
		local sRootMapping = LibraryData.getRootMapping("charsheet");
		for _,vNode in pairs(DB.getChildren(sRootMapping)) do
			local sName = DB.getValue(vNode, "name", "");
			if string.len(sName) > 0 then
				if string.lower(sFind) == string.lower(string.sub(sName, 1, string.len(sFind))) then
					nodeChar = vNode;
					break;
				end
			end
		end
		if not nodeChar then
			ChatManager.SystemMessage(Interface.getString("error_slashexportrecordmissing") .. " (" .. sParams .. ")");
			return;
		end
	end
	
	CampaignDataManager.exportChar(nodeChar);
end
function processExportNPC(sCommand, sParams)
	local nodeNPC = nil;
	
	local sFind = StringManager.trim(sParams);
	if string.len(sFind) > 0 then
		local sRootMapping = LibraryData.getRootMapping("npc");
		for _,vNode in pairs(DB.getChildren(sRootMapping)) do
			local sName = DB.getValue(vNode, "name", "");
			if string.len(sName) > 0 then
				if string.lower(sFind) == string.lower(string.sub(sName, 1, string.len(sFind))) then
					nodeNPC = vNode;
					break;
				end
			end
		end
		if not nodeNPC then
			ChatManager.SystemMessage(Interface.getString("error_slashexportrecordmissing") .. " (" .. sParams .. ")");
			return;
		end
	end
	
	CampaignDataManager.exportNPC(nodeNPC);
end

--
-- MESSAGES
--

function createBaseMessage(rSource, sUser)
	-- Set up the basic message components
	local msg = {font = "systemfont", text = "", secret = false};

	-- Add portrait
	if Session.IsHost then
		msg.icon = "portrait_gm_token";
	else
		if ActorManager.isPC(rSource) then
			local nodeActor = ActorManager.getCreatureNode(rSource);
			if nodeActor then
				msg.icon = "portrait_" .. nodeActor.getName() .. "_chat";
			end
		else
			local sIdentity = User.getCurrentIdentity();
			if sIdentity then
				msg.icon = "portrait_" .. sIdentity .. "_chat";
			end
		end
	end

	-- If actor specified
	if rSource then
		msg.sender = ActorManager.getDisplayName(rSource);
		
	-- Otherwise, use provided user name
	elseif sUser then
		msg.sender = sUser;
	
	-- Otherwise, use the current identity or user name
	else
		if Session.IsHost then
			msg.sender = GmIdentityManager.getCurrent()
		else
			msg.sender = User.getIdentityLabel();
		end

		if not msg.sender or msg.sender == "" then
			msg.sender = User.getUsername();
		end
	end
	
	-- RESULTS
	return msg;
end

function Message(msgtxt, broadcast, rActor)
	local msg = ChatManager.createBaseMessage(rActor);
	msg.text = msg.text .. msgtxt;

	if broadcast then
		Comm.deliverChatMessage(msg);
	else
		msg.secret = true;
		Comm.addChatMessage(msg);
	end
end
function SystemMessage(sText)
	local msg = {font = "systemfont"};
	msg.text = sText;
	Comm.addChatMessage(msg);
end

--
-- WHISPERS
--

local _sLastWhisperer = nil;

function processWhisper(sCommand, sParams)
	-- Find the target user for the whisper
	local sLowerParams = string.lower(sParams);
	local sGMIdentity = "gm ";

	local sRecipient = nil;
	if string.sub(sLowerParams, 1, string.len(sGMIdentity)) == sGMIdentity then
		sRecipient = "GM";
	else
		for _,vID in ipairs(User.getAllActiveIdentities()) do
			local sIdentity = User.getIdentityLabel(vID);

			local sIdentityMatch = string.lower(sIdentity) .. " ";
			if string.sub(sLowerParams, 1, string.len(sIdentityMatch)) == sIdentityMatch then
				if sRecipient then
					if #sRecipient < #sIdentity then
						sRecipient = sIdentity;
					end
				else
					sRecipient = sIdentity;
				end
			end
		end
	end
	
	local sMessage;
	if sRecipient then
		sMessage = string.sub(sParams, #sRecipient + 2)
	else
		sMessage = sParams;
	end
	
	ChatManager.processWhisperHelper(sRecipient, sMessage);
end
function processReply(sCommand, sParams)
	if not _sLastWhisperer then
		ChatManager.SystemMessage(Interface.getString("error_slashreplytargetmissing"));
		return;
	end
	ChatManager.processWhisperHelper(_sLastWhisperer, sParams);
end
function processWhisperHelper(sRecipient, sMessage)
	-- Make sure we have a valid identity and valid user owning the identity
	local sUser = nil;
	local sRecipientID = nil;
	if sRecipient then
		if sRecipient == "GM" then
			sRecipientID = "";
			sUser = "";
		else
			for _,vID in ipairs(User.getAllActiveIdentities()) do
				local sIdentity = User.getIdentityLabel(vID);
				if sIdentity == sRecipient then
					sRecipientID = vID;
					sUser = User.getIdentityOwner(vID);
				end
			end
		end
	end
	if not sRecipientID or not sUser then
		ChatManager.SystemMessage(Interface.getString("error_slashwhispertargetmissing"));
		ChatManager.SystemMessage("Usage: /w GM [message]\rUsage: /w [recipient] [message]");
		return;
	end
	
	-- Check for empty message
	if sMessage == "" then
		ChatManager.SystemMessage(Interface.getString("error_slashwhispermsgmissing"));
		ChatManager.SystemMessage("Usage: /w GM [message]\rUsage /w [recipient] [message]");
		return;
	end
	
	-- Make sure we have a user identity
	local sSender;
	if Session.IsHost then
		sSender = "";
	else
		sSender = User.getCurrentIdentity();
		if not sSender then
			ChatManager.SystemMessage(Interface.getString("error_slashwhispersourcemissing"));
			return;
		end
	end
	
	-- Send the whisper
	local msgOOB = {};
	msgOOB.type = ChatManager.OOB_MSGTYPE_WHISPER;
	msgOOB.sender = sSender;
	msgOOB.receiver = sRecipientID;
	msgOOB.text = sMessage;

	if Session.IsHost then
		Comm.deliverOOBMessage(msgOOB, { sUser, "" });
	else
		Comm.deliverOOBMessage(msgOOB);
	end
	
	-- Show what the user whispered
	local msg = { font = "whisperfont", sender = "", mode="whisper", icon = { "indicator_whisper" } };
	
	if Session.IsHost then
		table.insert(msg.icon, "portrait_gm_token");
	else
		if #(User.getOwnedIdentities()) > 1 then
			msg.sender = User.getIdentityLabel(sSender);
		end
		table.insert(msg.icon, "portrait_" .. msgOOB.sender .. "_chat");
	end

	msg.sender = msg.sender .. " -> " .. sRecipient;
	msg.text = sMessage;
	
	Comm.addChatMessage(msg);
end
function handleWhisper(msgOOB)
	-- Validate
	if not msgOOB.sender or not msgOOB.receiver or not msgOOB.text then
		return;
	end

	local bRing = OptionsManager.isOption("CWHR", "on");
	
	-- Check to see if GM has asked to see whispers
	if Session.IsHost then
		if msgOOB.sender == "" then
			return;
		end
		if msgOOB.receiver ~= "" then
			if OptionsManager.isOption("SHPW", "off") then
				return;
			end
			bRing = false;
		end
		
	-- Ignore messages not targeted to this user
	else
		if msgOOB.receiver == "" then
			return;
		end
		if not User.isOwnedIdentity(msgOOB.receiver) then
			return;
		end
	end
	
	-- Get the send and receiver labels
	local sSender, sReceiver;
	if msgOOB.sender == "" then
		sSender = "GM";
	else
		sSender = User.getIdentityLabel(msgOOB.sender) or "<unknown>";
	end
	if msgOOB.receiver == "" then
		sReceiver = "GM";
	else
		sReceiver = User.getIdentityLabel(msgOOB.receiver) or "<unknown>";
	end
	
	-- Remember last whisperer
	if not Session.IsHost or msgOOB.receiver == "" then
		_sLastWhisperer = sSender;
	end
	
	-- Build the message to display
	local msg = { font = "whisperfont", text = "", mode = "whisper", icon = { "indicator_whisper" } };
	msg.sender = sSender;
	if msgOOB.sender == "" then
		table.insert(msg.icon, "portrait_gm_token");
	else
		table.insert(msg.icon, "portrait_" .. msgOOB.sender .. "_chat");
	end
	if Session.IsHost then
		if msgOOB.receiver ~= "" then
			msg.sender = msg.sender .. " -> " .. sReceiver;
		end
	else
		if #(User.getOwnedIdentities()) > 1 then
			msg.sender = msg.sender .. " -> " .. sReceiver;
		end
	end
	msg.text = msg.text .. msgOOB.text;
	
	-- Show whisper message
	Comm.addChatMessage(msg);
	if bRing then 
		User.ringBell(); 
	end
end

function sendWhisperToID(sIdentity)
	local w = ChatManager.getChatWindow();
	if not w then
		return
	end
	
	local sCommand = "/w " .. User.getIdentityLabel(sIdentity) .. " ";
	w.entry.setValue(sCommand);
	w.entry.setFocus();
	w.entry.setCursorPosition(#sCommand + 1);
end
function sendWhisperToGM()
	local w = ChatManager.getChatWindow();
	if not w then
		return
	end
	
	local sCommand = "/w GM ";
	w.entry.setValue(sCommand);
	w.entry.setFocus();
	w.entry.setCursorPosition(#sCommand + 1);
end
