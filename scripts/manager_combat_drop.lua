-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CombatDropManager.addStandardDragTypeDropCallbacks();
end
function addStandardDragTypeDropCallbacks()
	if Session.IsHost then
		CombatDropManager.setDragTypeDropCallback("combattrackerff", CombatDropManager.onFactionDragTypeDrop);
		CombatDropManager.setDragTypeDropCallback("targeting", CombatDropManager.onTargetingDragTypeDrop);
	end
	CombatDropManager.setDragTypeDropCallback("effect_targeting", CombatDropManager.onEffectTargetingDragTypeDrop);
end

--
-- HANDLERS
--

local _tLinkDropCallbacks = {};
function setLinkDropCallback(sClass, fn)
	UtilityManager.setKeySingleCallback(_tLinkDropCallbacks, sClass, fn);
end
function getLinkDropCallback(sClass)
	return UtilityManager.getKeySingleCallback(_tLinkDropCallbacks, sClass);
end
function hasLinkDropCallback(sClass)
	return UtilityManager.hasKeySingleCallback(_tLinkDropCallbacks, sClass);
end
function onLinkDropEvent(sClass, tCustom)
	return UtilityManager.performKeySingleCallback(_tLinkDropCallbacks, sClass, tCustom);
end

local _tDragTypeDropCallbacks = {};
function setDragTypeDropCallback(sDragType, fn)
	UtilityManager.setKeySingleCallback(_tDragTypeDropCallbacks, sDragType, fn);
end
function getDragTypeDropCallback(sDragType)
	return UtilityManager.getKeySingleCallback(_tDragTypeDropCallbacks, sDragType);
end
function hasDragTypeDropCallback(sDragType)
	return UtilityManager.hasKeySingleCallback(_tDragTypeDropCallbacks, sDragType);
end
function onDragTypeDropEvent(sDragType, tCustom)
	return UtilityManager.performKeySingleCallback(_tDragTypeDropCallbacks, sDragType, tCustom);
end

local _fnActionCallback = nil;
function setActionDropCallback(fn)
	_fnActionCallback = fn;
end
function getActionDropCallback()
	return _fnActionCallback;
end

-- NOTE: Handlers added here will all be called in the order they were added.
local _tLegacyDropCallbacks = {};
function registerLegacyDropCallback(fn)
	UtilityManager.registerCallback(_tLegacyDropCallbacks, fn);
end
function onLegacyDropEvent(rSource, rTarget, draginfo)
	UtilityManager.performAllCallbacks(_tLegacyDropCallbacks, rSource, rTarget, draginfo);
end

--
-- DROP HANDLING
--

function handleAnyDrop(draginfo, sTargetPath)
	-- Legacy callback handling (Part 1)
	local bHandled, bReturn = CombatDropManager.handleLegacyDropOverride(draginfo);
	if bHandled then
		return bReturn;
	end

	-- Link handling
	local bHandled, bReturn = CombatDropManager.handleLinkDropEvent(draginfo, sTargetPath);
	if bHandled then
		return bReturn;
	end

	-- Custom drag types
	local bHandled, bReturn = CombatDropManager.handleDragTypeDropEvent(draginfo, sTargetPath);
	if bHandled then
		return bReturn;
	end

	-- Game system actions
	local bHandled, bReturn = CombatDropManager.handleActionDropEvent(draginfo, sTargetPath);
	if bHandled then
		return bReturn;
	end

	-- Legacy (Part 2)
	return CombatDropManager.handleLegacyDropEvent(draginfo, sTargetPath);
end

function handleLegacyDropOverride(draginfo)
	if not CampaignDataManager2 then
		return false;
	end
	if not CampaignDataManager2.handleDrop then
		return false;
	end
	if not CampaignDataManager2.handleDrop("combattracker", draginfo) then
		return false;
	end
	return true, true;
end
function handleLinkDropEvent(draginfo, sTargetPath)
	local sDragType = draginfo.getType();
	if sDragType ~= "shortcut" then
		return false;
	end

	-- Setup
	local tCustom = { draginfo = draginfo, sTargetPath = sTargetPath };
	tCustom.sClass, tCustom.sRecord = draginfo.getShortcutData();

	-- Handle record type links
	local sRecordType = LibraryData.getRecordTypeFromDisplayClass(tCustom.sClass);
	if CombatRecordManager.hasRecordTypeCallback(sRecordType) then
		CombatRecordManager.onRecordTypeEvent(sRecordType, tCustom);
		return true, true;
	end

	-- Non record type link always returns false right now
	local bResult = CombatDropManager.onLinkDropEvent(tCustom.sClass, tCustom);
	return true, bResult;
end
function handleDragTypeDropEvent(draginfo, sTargetPath)
	local sDragType = draginfo.getType();
	if not CombatDropManager.hasDragTypeDropCallback(sDragType) then
		return false;
	end

	local tCustom = { draginfo = draginfo, sDragType = sDragType, sTargetPath = sTargetPath };
	local bResult = CombatDropManager.onDragTypeDropEvent(sDragType, tCustom);
	return true, bResult;
end
function handleActionDropEvent(draginfo, sTargetPath)
	local sDragType = draginfo.getType();
	if not StringManager.contains(GameSystem.targetactions, sDragType) then
		return false;
	end

	local rTarget = ActorManager.resolveActor(sTargetPath);

	local fOverride = CombatDropManager.getActionDropCallback();
	if fOverride then
		local bResult = fOverride(draginfo, rTarget);
		return true, bResult;
	end
	
	ActionsManager.actionDrop(draginfo, rTarget);
	return true, true;
end
function handleLegacyDropEvent(draginfo, sTargetPath)
	local rSource = ActionsManager.decodeActors(draginfo);
	local rTarget = ActorManager.resolveActor(sTargetPath);
	return CombatDropManager.onLegacyDropEvent(rSource, rTarget, draginfo);
end

function onFactionDragTypeDrop(tCustom)
	local rTarget = ActorManager.resolveActor(tCustom.sTargetPath);
	if not rTarget then
		return false;
	end

	local sFaction = tCustom.draginfo.getStringData();
	DB.setValue(ActorManager.getCTNode(rTarget), "friendfoe", "string", sFaction);
	return true;
end
function onTargetingDragTypeDrop(tCustom)
	local rTarget = ActorManager.resolveActor(tCustom.sTargetPath);
	if not rTarget then
		return false;
	end

	local _,sNodeSourceCT = tCustom.draginfo.getShortcutData();
	local nodeSourceCT = DB.findNode(sNodeSourceCT);
	TargetingManager.addCTTarget(nodeSourceCT, ActorManager.getCTNode(rTarget));
	return true;
end
function onEffectTargetingDragTypeDrop(tCustom)
	local rTarget = ActorManager.resolveActor(tCustom.sTargetPath);
	if not rTarget then
		return false;
	end

	local _,sEffectNode = tCustom.draginfo.getShortcutData();
	EffectManager.addEffectTarget(sEffectNode, ActorManager.getCTNodeName(rTarget));
	return true;
end
