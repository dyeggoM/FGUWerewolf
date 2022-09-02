-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onEffectsChanged();
	local node = window.getDatabaseNode();
	DB.addHandler(DB.getPath(node, "effects"), "onChildUpdate", onEffectsChanged);
end

function onClose()
	local node = window.getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "effects"), "onChildUpdate", onEffectsChanged);
end

function onToggle()
	self.onEffectsChanged();
end

function onEffectsChanged()
	-- Set the effect summary string
	local sEffects = EffectManager.getEffectsString(window.getDatabaseNode());
	if sEffects ~= "" then
		setValue(Interface.getString("ct_label_effects") .. " " .. sEffects);
	else
		setValue(nil);
	end
	
	-- Update visibility
	local bSectionToggle = (window.activateeffects and (window.activateeffects.getValue() == 1)) or
				(window.getSectionToggle and (window.getSectionToggle("effects") == true));
	local bShow = (sEffects ~= "") and not bSectionToggle;
	setVisible(bShow);
end
