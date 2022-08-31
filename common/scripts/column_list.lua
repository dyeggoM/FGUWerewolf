-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if isReadOnly() then
		self.update(true);
	else
		local node = getDatabaseNode();
		if not node or node.isReadOnly() then
			self.update(true);
		end
	end
end

function update(bReadOnly, bForceHide)
	local bLocalShow;
	if bForceHide then
		bLocalShow = false;
	else
		bLocalShow = true;
		if bReadOnly and not nohide and (getWindowCount() == 0) then
			bLocalShow = false;
		end
	end
	
	setVisible(bLocalShow);
	setReadOnly(bReadOnly);

	local sListName = getName();
	if window[sListName .. "_header"] then
		window[sListName .. "_header"].setVisible(bLocalShow);
	end
	
	local bEditMode = false;
	local cButtonEdit = window[sListName .. "_iedit"];
	if cButtonEdit then
		if bReadOnly then
			cButtonEdit.setValue(0);
			cButtonEdit.setVisible(false);
		else
			cButtonEdit.setVisible(true);
			bEditMode = (cButtonEdit.getValue() ~= 0);
		end
	end
	local cButtonAdd = window[sListName .. "_iadd"];
	if cButtonAdd then
		if bReadOnly then
			cButtonAdd.setVisible(false);
		else
			cButtonAdd.setVisible(true);
		end
	end

	for _,w in ipairs(getWindows()) do
		if w.update then
			w.update(bReadOnly);
		elseif w.name then
			w.name.setReadOnly(bReadOnly);
		end
		w.idelete.setVisibility(bEditMode);
	end
	
	return bLocalShow;
end
