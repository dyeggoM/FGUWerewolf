-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.update();
end

function VisDataCleared()
	self.update();
end

function InvisDataAdded()
	self.update();
end

function onDrop(x, y, draginfo)
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	if bReadOnly then
		return false;
	end
	return ItemManager.handleAnyDropOnItemRecord(nodeRecord, draginfo);
end

function updateControl(sControl, bReadOnly, bID)
	if not self[sControl] then
		return false;
	end
		
	if not bID then
		return self[sControl].update(bReadOnly, true);
	end
	
	return self[sControl].update(bReadOnly);
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("item", nodeRecord);
	
	local bSection1 = false;
	if Session.IsHost then
		if self.updateControl("nonid_name", bReadOnly, true) then bSection1 = true; end;
	else
		self.updateControl("nonid_name", bReadOnly, false);
	end
	if (Session.IsHost or not bID) then
		if self.updateControl("nonid_notes", bReadOnly, true) then bSection1 = true; end;
	else
		self.updateControl("nonid_notes", bReadOnly, false);
	end
	
	local bSection2 = false;
	if self.updateControl("cost", bReadOnly, bID) then bSection2 = true; end
	if self.updateControl("weight", bReadOnly, bID) then bSection2 = true; end

	local bSection3 = bID;
	notes.setVisible(bID);
	notes.setReadOnly(bReadOnly);
		
	divider.setVisible(bSection1 and bSection2);
	divider2.setVisible((bSection1 or bSection2) and bSection3);

	if ItemManager.isPack(nodeRecord) then
		sub_subitems.setValue("item_main_subitems", nodeRecord);
	else
		sub_subitems.setValue("", "");
	end
	sub_subitems.update(bReadOnly);
end
