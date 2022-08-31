-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _sRecordType;

function onInit()
	self.initRecordType();
	self.update();
end

function initRecordType()
	local sClass = UtilityManager.getTopWindow(self).getClass();
	_sRecordType = LibraryData.getRecordTypeFromDisplayClass(sClass);

	link.setValue(sClass);
	name.setEmptyText(Interface.getString("library_recordtype_empty_" .. _sRecordType));
	nonid_name.setEmptyText(Interface.getString("library_recordtype_empty_nonid_" .. _sRecordType));
end

function update()
	if not _sRecordType then
		return;
	end

	local nodeRecord = getDatabaseNode();

	-- Update name/token edit modes
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	name.setReadOnly(bReadOnly);
	nonid_name.setReadOnly(bReadOnly);
	if token then
		token.setReadOnly(bReadOnly);
	end

	-- Update name field visibility
	local bID = LibraryData.getIDState(_sRecordType, nodeRecord);
	name.setVisible(bID);
	nonid_name.setVisible(not bID);

	-- Update tooltip
	local sTooltip;
	if bID then
		sTooltip = DB.getValue(nodeRecord, "name", "");
		if sTooltip == "" then
			sTooltip = Interface.getString("library_recordtype_empty_" .. _sRecordType);
		end
	else
		sTooltip = DB.getValue(nodeRecord, "nonid_name", "");
		if sTooltip == "" then
			sTooltip = Interface.getString("library_recordtype_empty_nonid_" .. _sRecordType);
		end
	end
	if parentcontrol then
		parentcontrol.window.setTooltipText(sTooltip);
	end
	if link then
		link.setTooltipText(sTooltip);
	end
end

function onIDChanged()
	self.update();
end
function onNameUpdated()
	self.update();
end

-- Legacy compatibility
function updateIDState()
	self.update();
end
