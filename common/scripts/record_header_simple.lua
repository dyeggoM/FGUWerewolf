-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.update();
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	name.setReadOnly(bReadOnly);
end
