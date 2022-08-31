-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onLockChanged()
	if header and header.subwindow then
		header.subwindow.update();
	end
	
	if content and content.subwindow then
		content.subwindow.update();
	elseif main and main.subwindow then
		main.subwindow.update();
	end
	
	if text then
		local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
		text.setReadOnly(bReadOnly);
	elseif notes then
		local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
		notes.setReadOnly(bReadOnly);
	elseif description then
		local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
		description.setReadOnly(bReadOnly);
	end
end

-- Legacy compatibility for Savage Worlds
function update()
	self.onLockChanged();
end
