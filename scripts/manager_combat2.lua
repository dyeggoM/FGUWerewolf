-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CombatManager.setCustomSort(CombatManager.sortfuncStandard);
	CombatManager.setCustomCombatReset(resetInit);
	ActorCommonManager.setRecordTypeSpaceReachCallback("npc", ActorCommonManager.getSpaceReachCore);
	ActorCommonManager.setRecordTypeSpaceReachCallback("vehicle", ActorCommonManager.getSpaceReachCore);
end

--
-- ACTIONS
--

function resetInit()
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		DB.setValue(v, "initresult", "number", 0);
	end
end
