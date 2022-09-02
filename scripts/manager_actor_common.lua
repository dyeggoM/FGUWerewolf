-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
-- Common space and reach calculations
--

local _tSpaceReachCallbacks = {};
function setRecordTypeSpaceReachCallback(sRecordType, fn)
	UtilityManager.setKeySingleCallback(_tSpaceReachCallbacks, sRecordType, fn);
end
function getRecordTypeSpaceReachCallback(sRecordType)
	return UtilityManager.getKeySingleCallback(_tSpaceReachCallbacks, sRecordType);
end
function hasRecordTypeSpaceReachCallback(sRecordType)
	return UtilityManager.hasKeySingleCallback(_tSpaceReachCallbacks, sRecordType);
end
function onRecordTypeSpaceReachEvent(sRecordType, rActor)
	return UtilityManager.performKeySingleCallback(_tSpaceReachCallbacks, sRecordType, rActor);
end

function getSpaceReach(v)
	local rActor = ActorManager.resolveActor(v);
	if not rActor then
		return {};
	end
	
	local sRecordType = ActorManager.getRecordType(rActor);

	-- Legacy handling
	if sRecordType == "npc" then
		local fOverride = CombatManager.getCustomNPCSpaceReach();
		if fOverride then
			local nodeActor = ActorManager.getCreatureNode(rActor);
			return fOverride(nodeActor);
		end
	end

	-- Standard handling
	if ActorCommonManager.hasRecordTypeSpaceReachCallback(sRecordType) then
		return ActorCommonManager.onRecordTypeSpaceReachEvent(sRecordType, rActor);
	end

	-- Default (1x1 grid)
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	return nDU, nDU;
end

function getSpaceReachCore(rActor)
	local nSpace = GameSystem.getDistanceUnitsPerGrid();
	local nReach = nSpace;

	local nodeActor = ActorManager.getCreatureNode(rActor);
	if nodeActor then
		nSpace = tonumber(DB.getValue(nodeActor, "space", nDU)) or nSpace;
		nReach = tonumber(DB.getValue(nodeActor, "reach", nDU)) or nReach;
	end

	return nSpace, nReach;
end
function getSpaceReachDnD3Legacy(rActor)
	local nSpace = GameSystem.getDistanceUnitsPerGrid();
	local nReach = nSpace;
	
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if nodeActor then
		local sSpaceReach = DB.getValue(nodeActor, "spacereach", "");
		local sSpace, sReach = string.match(sSpaceReach, "(%d+)%D*/?(%d+)%D*");
		if sSpace then
			nSpace = tonumber(sSpace) or nSpace;
			nReach = tonumber(sReach) or nReach;
		end
	end
	
	return nSpace, nReach;
end
function getSpaceReachFromTypeFieldCore(rActor)
	local nSpace = GameSystem.getDistanceUnitsPerGrid();
	local nReach = nSpace;
	
	local nActorSize = ActorCommonManager.getCreatureSizeFromTypeFieldCore(rActor);
	if nActorSize == -2 then
		--nSpace = 1;
		nReach = 0;
	elseif nActorSize == -1 then
		--nSpace = 1;
		--nReach = 1;
	elseif nActorSize == 0 then
		--nSpace = 1;
		--nReach = 1;
	elseif nActorSize == 1 then
		nSpace = nSpace * 2;
		--nReach = 1;
	elseif nActorSize == 2 then
		nSpace = nSpace * 3;
		nReach = nReach * 2;
	elseif nActorSize == 3 then
		nSpace = nSpace * 4;
		nReach = nReach * 3;
	end
	
	return nSpace, nReach;
end
function getSpaceReachFromSizeFieldCore(rActor)
	local nSpace = GameSystem.getDistanceUnitsPerGrid();
	local nReach = nSpace;

	local nActorSize = ActorCommonManager.getCreatureSizeFromSizeFieldCore(rActor);
	if nActorSize == 1 then
		nSpace = nSpace * 2;
	elseif nActorSize == 2 then
		nSpace = nSpace * 3;
	elseif nActorSize == 3 then
		nSpace = nSpace * 4;
	elseif nActorSize == 4 then
		nSpace = nSpace * 5;
	end

	return nSpace, nReach;
end

--
--	Common creature size check functions
--

-- Known usage notes:
--		5E, DCC, MCC - size
function isCreatureSizeDnD5(rActor, sParam)
	if not DataCommon.creaturesize then
		return false;
	end

	local tParamSize = ActorCommonManager.internalIsCreatureSizeDnDParam(sParam);
	if not tParamSize then
		return false;
	end
	
	local nActorSize = ActorCommonManager.getCreatureSizeDnD5(rActor);
	return ActorCommonManager.internalIsCreatureSizeDnDCompare(tParamSize, nActorSize);
end

-- Known usage notes:
--		4E/3.5E/PFRPG/SFRPG/13A/d20Modern - size(PC) or type(NPC)
function isCreatureSizeDnD3(rActor, sParam)
	if not DataCommon.creaturesize then
		return false;
	end

	local tParamSize = ActorCommonManager.internalIsCreatureSizeDnDParam(sParam);
	if not tParamSize then
		return false;
	end
	
	local nActorSize = ActorCommonManager.getCreatureSizeDnD3(rActor);

	return ActorCommonManager.internalIsCreatureSizeDnDCompare(tParamSize, nActorSize);
end

function internalIsCreatureSizeDnDParam(sParam)
	local tParams = StringManager.splitByPattern(sParam:lower(), ",", true);

	local tParamSize = {};
	for _,sParamComp in ipairs(tParams) do
		local sParamCompLower = StringManager.trim(sParamComp):lower();
		local sParamOp = sParamCompLower:match("^[<>]?=?");
		if sParamOp then
			sParamCompLower = StringManager.trim(sParamCompLower:sub(#sParamOp + 1));
		end
		local nParamSize = DataCommon.creaturesize[sParamCompLower];
		if nParamSize then
			table.insert(tParamSize, { nParamSize = nParamSize, sParamOp = sParamOp });
		end
	end
	if #tParamSize == 0 then
		return nil;
	end
	return tParamSize;
end

function internalIsCreatureSizeDnDCompare(tParamSize, nActorSize)
	for _,t in ipairs(tParamSize) do
		local bReturn;
		if t.sParamOp then
			if t.sParamOp == "<" then
				bReturn = (nActorSize < t.nParamSize);
			elseif t.sParamOp == ">" then
				bReturn = (nActorSize > t.nParamSize);
			elseif t.sParamOp == "<=" then
				bReturn = (nActorSize <= t.nParamSize);
			elseif t.sParamOp == ">=" then
				bReturn = (nActorSize >= t.nParamSize);
			else
				bReturn = (nActorSize == t.nParamSize);
			end
		else
			bReturn = (nActorSize == t.nParamSize);
		end
		if bReturn then
			return true;
		end
	end
	return false;
end

-- Known usage notes:
--		5E/DCC/MCC - size
function getCreatureSizeDnD5(rActor)
	return ActorCommonManager.getCreatureSizeFromSizeFieldCore(rActor);
end

-- Known usage notes:
--		4E/3.5E/PFRPG/SFRPG/13A/d20Modern - size(PC) or type(NPC)
function getCreatureSizeDnD3(rActor)
	if ActorManager.isPC(rActor) then
		return ActorCommonManager.getCreatureSizeFromSizeFieldCore(rActor);
	end
	return ActorCommonManager.getCreatureSizeFromTypeFieldCore(rActor);
end

function getCreatureSizeFromSizeFieldCore(rActor)
	if not DataCommon.creaturesize then
		return 0;
	end

	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return 0;
	end

	local nActorSize = nil;
	
	local sSize = DB.getValue(nodeActor, "size", ""):lower();
	local tLines = StringManager.splitLines(sSize);
	for _,sLine in ipairs(tLines) do
		local tWords = StringManager.parseWords(sLine);
		if tWords[1] and DataCommon.creaturesize[tWords[1]] then
			nActorSize = DataCommon.creaturesize[tWords[1]];
			break;
		end
	end
	
	return nActorSize or 0;
end

function getCreatureSizeFromTypeFieldCore(rActor)
	if not DataCommon.creaturesize then
		return 0;
	end

	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return 0;
	end

	local nActorSize = nil;
	
	local sType = DB.getValue(nodeActor, "type", ""):lower();
	local tLines = StringManager.splitLines(sType);
	for _,sLine in ipairs(tLines) do
		local tWords = StringManager.splitWords(sLine);
		if #tWords > 0 then
			if DataCommon.creaturesize[tWords[1]] then
				nActorSize = DataCommon.creaturesize[tWords[1]];
			elseif (DataCommon.alignment_lawchaos and DataCommon.alignment_lawchaos[tWords[1]])
					or (DataCommon.alignment_goodevil and DataCommon.alignment_goodevil[tWords[1]])
					or (DataCommon.alignment_neutral and (tWords[1] == DataCommon.alignment_neutral))
					then
				for _,sWord in ipairs(tWords) do
					if DataCommon.creaturesize[sWord] then
						nActorSize = DataCommon.creaturesize[sWord];
						break;
					end
				end
			end
		end
		if nActorSize then
			break;
		end
	end
	
	return nActorSize or 0;
end

--
--	Common creature type check functions
--

function isCreatureTypeDnD(rActor, sParam)
	local tCheckTypes = ActorCommonManager.internalGetCreatureTypeDnDParam(sParam);
	if not tCheckTypes then
		return false;
	end
	
	local tActorTypes = ActorCommonManager.internalGetCreatureTypeDnDActor(rActor);
	if not tActorTypes then
		return false;
	end

	for s,t in pairs(tCheckTypes) do
		for _,sCheck in ipairs(t) do
			if StringManager.contains(tActorTypes[s], sCheck) then
				return true;
			end
		end
	end
	return false;
end

-- Known usage notes:
--		5E/PFRPG/3.5E/SFRPG/d20Modern/DCC - type/subtype
--		4E - origin/type/subtype
--		13A/MCC - type
function getCreatureTypeDnD(sType, bUseDefaultType)
	-- Build parameter tracking
	local tSource = { nIndex = 1 };
	tSource.tWords = StringManager.split(sType:lower(), ", %(%)", true);
	
	-- Handle half races
	ActorCommonManager.internalHandleCreatureTypeDnDHalfType(tSource);
	
	-- Check each type set
	local tResult = {};
	tResult["origin"] = ActorCommonManager.internalIsCreatureTypeDnDMatch(tSource, DataCommon.creatureorigin, true, bUseDefaultType, DataCommon.creaturedefaultorigin);
	tResult["type"] = ActorCommonManager.internalIsCreatureTypeDnDMatch(tSource, DataCommon.creaturetype, true, bUseDefaultType, DataCommon.creaturedefaulttype);
	tResult["subtype"] = ActorCommonManager.internalIsCreatureTypeDnDMatch(tSource, DataCommon.creaturesubtype, false);
	
	-- Return types and subtypes
	return tResult;
end

function internalGetCreatureTypeDnDParam(sParam)
	local tParams = StringManager.splitByPattern(sParam:lower(), ",", true);

	local tCheckTypes = {};
	for _,sParamComp in ipairs(tParams) do
		local tParamCompTypes = ActorCommonManager.getCreatureTypeDnD(sParamComp, false);
		for sParamCompTypeKey, tParamCompType in pairs(tParamCompTypes) do
			if not tCheckTypes[sParamCompTypeKey] then
				tCheckTypes[sParamCompTypeKey] = {};
			end
			for _,s in ipairs(tParamCompType) do
				table.insert(tCheckTypes[sParamCompTypeKey], s);
			end
		end
	end

	for _,t in pairs(tCheckTypes) do
		if #t > 0 then
			return tCheckTypes;
		end
	end
	return nil;
end

function internalGetCreatureTypeDnDActor(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return nil;
	end

	local sField;
	if ActorManager.isPC(rActor) then
		sField = "race";
	else
		sField = "type";
	end
	local sActorType = DB.getValue(nodeActor, sField, "");
	return ActorCommonManager.getCreatureTypeDnD(sActorType, true);
end

function internalHandleCreatureTypeDnDHalfType(tSource)
	if DataCommon.creaturehalftype and DataCommon.creaturehalftypesubrace then
		local nHalfRace = 0;
		for n = 1, #(tSource.tWords) do
			if StringManager.startsWith(DataCommon.creaturehalftype, tSource.tWords[n]) then
				tSource.tWords[n] = tSource.tWords[n]:sub(#DataCommon.creaturehalftype + 1);
				nHalfRace = nHalfRace + 1;
			end
		end
		if nHalfRace == 1 then
			if not StringManager.contains(tSource.tWords, DataCommon.creaturehalftypesubrace) then
				table.insert(tSource.tWords, DataCommon.creaturehalftypesubrace);
			end
		end
	end
end

function internalIsCreatureTypeDnDMatch(tSource, tCheck, bSingle, bUseDefault, sDefault)
	if not tCheck then
		return nil;
	end

	local tResult = {};

	while tSource.nIndex <= #(tSource.tWords) do
		for _,sCheck in ipairs(tCheck) do
			local tCheckWords = StringManager.split(sCheck, " ", true);
			if #tCheckWords > 0 then
				local bMatch = true;
				for i = 1, #tCheckWords do
					if tCheckWords[i] ~= tSource.tWords[tSource.nIndex - 1 + i] then
						bMatch = false;
						break;
					end
				end
				if bMatch then
					table.insert(tResult, sCheck);
					tSource.nIndex = tSource.nIndex + (#tCheckWords - 1);
					break;
				end
			end
		end
		tSource.nIndex = tSource.nIndex + 1;
		if bSingle and (#tResult > 0) then
			break;
		end
	end
	if #tResult == 0 then
		if bUseDefault and ((sDefault or "") ~= "") then
			table.insert(tResult, sDefault);
		end
		tSource.nIndex = 1;
	end

	return tResult;
end

--
--	Common creature alignment check functions
--

-- Known usage notes:
--		5E/4E/3.5E/SFRPG/DCC/MCC - alignment
--		PFRPG - alignment(PC) or type(NPC)
function isCreatureAlignmentDnD(rActor, sParam)
	local tParamAlign = ActorCommonManager.internalGetCreatureAlignmentDnDParam(sParam);
	if not tParamAlign then
		return false;
	end
	
	local tActorAlign = ActorCommonManager.internalGetCreatureAlignmentDnDActor(rActor);
	if not tActorAlign then
		return false;
	end
	
	local bReturn = true;
	for _,t in ipairs(tParamAlign) do
		local bMatch = true;
		if t.nLawChaos and (t.nLawChaos ~= tActorAlign.nLawChaos) then
			bMatch = false;
		end
		if t.nGoodEvil and (t.nGoodEvil ~= tActorAlign.nGoodEvil) then
			bMatch = false;
		end
		if bMatch then
			return true;
		end
	end
	return false;
end

-- NOTE: Assume standard values of:
--		nCheckLawChaosAxis = Lawful = 1, Neutral = 2, Chaos = 3
--		nCheckGoodEvilAxis = Good = 1, Neutral = 2, Evil = 3
function getCreatureAlignmentDnD(s, bUseDefault)
	if not DataCommon.alignment_lawchaos or not DataCommon.alignment_goodevil then
		return nil;
	end

	-- Build parameter tracking
	local tWords = StringManager.splitWords(s:lower());
	
	local nCheckLawChaosAxis, nCheckGoodEvilAxis;
	for _,sWord in ipairs(tWords) do
		if not nCheckLawChaosAxis and DataCommon.alignment_lawchaos[sWord] then
			nCheckLawChaosAxis = DataCommon.alignment_lawchaos[sWord];
		end
		if not nCheckGoodEvilAxis and DataCommon.alignment_goodevil[sWord] then
			nCheckGoodEvilAxis = DataCommon.alignment_goodevil[sWord];
		end
	end
	if bUseDefault then
		if not nCheckLawChaosAxis then
			nCheckLawChaosAxis = 2;
		end
		if not nCheckGoodEvilAxis then
			nCheckGoodEvilAxis = 2;
		end
	else
		if not nCheckLawChaosAxis and not nCheckGoodEvilAxis then
			return nil;
		end
	end

	return { nLawChaos = nCheckLawChaosAxis, nGoodEvil = nCheckGoodEvilAxis };
end

function internalGetCreatureAlignmentDnDParam(sParam)
	local tParams = StringManager.splitByPattern(sParam:lower(), ",", true);

	local tParamAlign = {};
	for _,sParamComp in ipairs(tParams) do
		local tParamCompAlign = ActorCommonManager.getCreatureAlignmentDnD(sParamComp, false);
		if tParamCompAlign then
			table.insert(tParamAlign, tParamCompAlign);
		end
	end

	if #tParamAlign == 0 then
		return nil;
	end
	return tParamAlign;
end

function internalGetCreatureAlignmentDnDActor(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return nil;
	end

	if ActorManager.isPC(rActor) or (Session.RulesetName ~= "PFRPG") then
		sField = "alignment";
	else
		sField = "type";
	end
	local sActorAlign = DB.getValue(nodeActor, sField, "");
	return ActorCommonManager.getCreatureAlignmentDnD(sActorAlign, true);
end
