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
	if recordtype_label then
		recordtype_label.setValue(LibraryData.getSingleDisplayText(_sRecordType));
		recordtype_label.setVisible(true);
	end
end

function update()
	if not _sRecordType then
		return;
	end

	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	name.setReadOnly(bReadOnly);
	if token then
		token.setReadOnly(bReadOnly);
	end
end
