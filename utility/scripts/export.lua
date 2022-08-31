-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bDialogThumbnailOpen = false;

function onInit()
	onFileValueChanged();
	onNameValueChanged();

	ExportManager.performInit(self);
end
function onClose()
	if bDialogThumbnailOpen then
		Interface.dialogFileClose();
	end
end

function onFileValueChanged()
	local sFile = file.getValue();
	if sFile == "" then
		file.setFrame("required", 7, 6, 7, 6);
		file.setTooltipText(Interface.getString("export_tooltip_file_empty"));
	elseif not ExportManager.isFileNameValid(sFile) then
		file.setFrame("required", 7, 6, 7, 6);
		file.setTooltipText(Interface.getString("export_tooltip_file_invalid"));
	else
		file.setFrame(nil);
		file.setTooltipText("");
	end
end
function onThumbnailButtonPress()
	bDialogThumbnailOpen = Interface.dialogFileOpen(onThumbnailFileSelection, { png = "PNG Files" });
end
function onThumbnailFileSelection(result, path)
	bDialogThumbnailOpen = false;
	if result == "ok" then
		thumbnail.setValue(path);
	end
end
function onNameValueChanged()
	if name.isEmpty() then
		name.setFrame("required", 7, 6, 7, 6);
	else
		name.setFrame(nil);
	end
end

function onRecordTypeListDrop(draginfo)
	if draginfo.isType("shortcut") then
		for _,wRecordType in ipairs(recordtypes.getWindows()) do
			local sClass, sRecord = draginfo.getShortcutData();
		
			-- Find matching export category
			local bMatch = false;
			for _,vSource in ipairs(wRecordType.getSources()) do
				if sRecord:match("^" .. vSource .. "%.[^.]+$") then
					bMatch = true;
				end
			end
			if bMatch then
				-- Check duplicates
				for _,wExistingSingle in ipairs(wRecordType.entries.getWindows()) do
					local _,sExistingRecord = wExistingSingle.link.getValue();
					if sExistingRecord == sRecord then
						return true;
					end
				end
			
				-- Create entry
				local wNewSingle = wRecordType.entries.createWindow();
				wNewSingle.link.setValue(sClass, sRecord);
				
				wRecordType.select.setValue(0);
				break;
			end
		end
		return true;
	end
end
function onAssetListDrop(draginfo, cList)
	local sAsset = draginfo.getTokenData();
	if (sAsset or "") == "" then
		return nil;
	end
	
	-- Check for module tokens
	if sAsset and sAsset:find("@") then
		ChatManager.SystemMessage(Interface.getString("export_error_asset"));
		return true;
	end
	
	-- Check for duplicates
	for _,wExistingAsset in ipairs(cList.getWindows()) do
		if wExistingAsset.token.getValue() == sAsset then
			return true;
		end
	end
	
	-- If no duplicates, create new list entry
	local wNewAsset = cList.createWindow();
	wNewAsset.token.setValue(sAsset);
	return true;
end

function onRecordTypeSelectAll()
	for _,w in ipairs(recordtypes.getWindows()) do
		w.select.setValue(1);
	end
end
function onRecordTypeSelectNone()
	for _,w in ipairs(recordtypes.getWindows()) do
		w.select.setValue(0);
	end
end

function performClear()
	ExportManager.performClear(self);
end
function performExport()
	ExportManager.performExport(self);
end
