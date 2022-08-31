-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
--	INDEX HANDLING
--

function openRecordIndex(sRecordType)
	if ((sRecordType or "") == "") then
		return;
	end

	local w = Interface.findWindow("masterindex", sRecordType);
	if w then
		return w, true;
	end
	w = Interface.openWindow("masterindex", sRecordType);
	return w, false;
end

--
--  FIND RECORD HELPERS
--

function findRecordByString(sRecordType, sField, sValue)
	if not sRecordType then
		return nil;
	end
	if ((sField or "") == "") or ((sValue or "") == "") then
		return nil;
	end

	local sFind = StringManager.trim(sValue);
	
	local tMappings = LibraryData.getMappings(sRecordType);
	for _,sMapping in ipairs(tMappings) do
		for _,v in pairs(DB.getChildrenGlobal(sMapping)) do
			local sMatch = StringManager.trim(DB.getValue(v, sField, ""));
			if sMatch == sFind then
				return v;
			end
		end
	end
	
	return nil;
end

function findRecordByStringI(sRecordType, sField, sValue)
	if not sRecordType then
		return nil;
	end
	if ((sField or "") == "") or ((sValue or "") == "") then
		return nil;
	end
	
	local sFind = StringManager.trim(sValue):lower();
	
	local tMappings = LibraryData.getMappings(sRecordType);
	for _,sMapping in ipairs(tMappings) do
		for _,v in pairs(DB.getChildrenGlobal(sMapping)) do
			local sMatch = StringManager.trim(DB.getValue(v, sField, "")):lower();
			if sMatch == sFind then
				return v;
			end
		end
	end
	
	return nil;
end

--
--  CALL FOR ALL RECORDS HELPERS
--

function callForEachRecord(sRecordType, fn, ...)
	if not sRecordType or not fn then
		return;
	end

	local tMappings = LibraryData.getMappings(sRecordType);
	for _,sMapping in ipairs(tMappings) do
		for _,v in pairs(DB.getChildrenGlobal(sMapping)) do
			fn(v, ...);
		end
	end
end

function callForEachCampaignRecord(sRecordType, fn, ...)
	if not sRecordType or not fn then
		return;
	end

	local tMappings = LibraryData.getMappings(sRecordType);
	for _,sMapping in ipairs(tMappings) do
		for _,v in pairs(DB.getChildren(sMapping)) do
			fn(v, ...);
		end
	end
end

function callForEachRecordByString(sRecordType, sField, sValue, fn, ...)
	if not sRecordType or not fn then
		return;
	end
	if ((sField or "") == "") or ((sValue or "") == "") then
		return;
	end

	local sFind = StringManager.trim(sValue);

	local tMappings = LibraryData.getMappings(sRecordType);
	for _,sMapping in ipairs(tMappings) do
		for _,v in pairs(DB.getChildrenGlobal(sMapping)) do
			local sMatch = StringManager.trim(DB.getValue(v, sField, ""));
			if sMatch == sFind then
				fn(v, ...);
			end
		end
	end
end

function callForEachRecordByStringI(sRecordType, sField, sValue, fn, ...)
	if not sRecordType or not fn then
		return;
	end
	if ((sField or "") == "") or ((sValue or "") == "") then
		return;
	end

	local sFind = StringManager.trim(sValue):lower();

	local tMappings = LibraryData.getMappings(sRecordType);
	for _,sMapping in ipairs(tMappings) do
		for _,v in pairs(DB.getChildrenGlobal(sMapping)) do
			local sMatch = StringManager.trim(DB.getValue(v, sField, "")):lower();
			if sMatch == sFind then
				fn(v, ...);
			end
		end
	end
end

