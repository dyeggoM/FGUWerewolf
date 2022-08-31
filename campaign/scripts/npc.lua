-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.onStateChanged();
	self.onIDChanged();
end

function onLockChanged()
	self.onStateChanged();
end

function onStateChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	if main.subwindow then
		main.subwindow.update();
	end

	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	notes.setReadOnly(bReadOnly);
end

function onIDChanged()
	if Session.IsHost then
		if main.subwindow then
			main.subwindow.update();
		end
	else
		local bID = LibraryData.getIDState("npc", getDatabaseNode(), true);
		tabs.setVisibility(bID);
	end
end
