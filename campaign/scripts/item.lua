-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- DEPRECATED - 2022-07 - Only used in child rulesets

function onInit()
	Debug.console("campaign/scripts/item.lua - DEPRECATED - 2022-07-12 - Use common/scripts/record_window.lua");
	onStateChanged();
end

function onLockChanged()
	onStateChanged();
end
function onIDChanged()
	onStateChanged();
end

function onStateChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	if main.subwindow then
		main.subwindow.update();
	end
end
