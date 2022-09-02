-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end
function VisDataCleared()
	update();
end
function InvisDataAdded()
	update();
end

function updateControl(sControl, bReadOnly, bForceHide)
	if not self[sControl] then
		return false;
	end
		
	return self[sControl].update(bReadOnly, bForceHide);
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("npc", nodeRecord);

	local bSection1 = false;
	if Session.IsHost then
		if updateControl("nonid_name", bReadOnly) then bSection1 = true; end;
	else
		updateControl("nonid_name", bReadOnly, true);
	end
	divider.setVisible(bSection1);
	
	local bSection2 = false;
	if updateControl("type", bReadOnly) then bSection2 = true; end;
	divider2.setVisible(bSection2);

	space.setReadOnly(bReadOnly);
	reach.setReadOnly(bReadOnly);
	updateControl("cost", bReadOnly);
	updateControl("weight", bReadOnly);
	updateControl("speed", bReadOnly);
	
	notes.setReadOnly(bReadOnly);
end
