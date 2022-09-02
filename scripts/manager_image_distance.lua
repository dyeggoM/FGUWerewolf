-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _nDefaultDiagMult;
function onInit()
	_nDefaultDiagMult = Interface.getDistanceDiagMult();
	OptionsManager.registerCallback("HRDD", ImageDistanceManager.onDistanceOptionChanged);

	Interface.onDesktopInit = onDesktopInit;
end
function onDesktopInit()
	ImageDistanceManager.onDistanceOptionChanged();
end

function onDistanceOptionChanged()
	if OptionsManager.isOption("HRDD", "x1") then
		Interface.setDistanceDiagMult(1);
	elseif OptionsManager.isOption("HRDD", "variant") then
		Interface.setDistanceDiagMult(1.5);
	elseif OptionsManager.isOption("HRDD", "raw") then
		Interface.setDistanceDiagMult("*");
	else
		Interface.setDistanceDiagMult(_nDefaultDiagMult);
	end
end

