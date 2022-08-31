-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local m_sIndexPath = "";
local m_sPrevPath = "";
local m_sNextPath = "";

function onInit()
	local vNode = getDatabaseNode();
	local sPath = vNode.getPath();
	
	local sRootMapping = LibraryData.getRootMapping("story");
	local wIndex, bWasIndexOpen = RecordManager.openRecordIndex(sRootMapping);
	
	if wIndex then
		local vIndexNode = wIndex.getIndexRecord(vNode);
		if vIndexNode then
			m_sIndexPath = vIndexNode.getPath();
		end
		local vPrevNode = wIndex.getPrevRecord(vNode);
		if vPrevNode then
			m_sPrevPath = vPrevNode.getPath();
		end
		local vNextNode = wIndex.getNextRecord(vNode);
		if vNextNode then
			m_sNextPath = vNextNode.getPath();
		end
		if not bWasIndexOpen then
			wIndex.close();
		end
	end
	
	page_top.setVisible(m_sIndexPath ~= "");
	page_prev.setVisible(m_sPrevPath ~= "");
	page_next.setVisible(m_sNextPath ~= "");
end

function handlePageTop()
	if m_sIndexPath ~= "" then
		replaceWindow(m_sIndexPath);
	end
end

function handlePagePrev()
	if m_sPrevPath ~= "" then
		replaceWindow(m_sPrevPath);
	end
end

function handlePageNext()
	if m_sNextPath ~= "" then
		replaceWindow(m_sNextPath);
	end
end

function replaceWindow(sPath)
	local x,y = getPosition();
	local w,h = getSize();
	local wNew = Interface.openWindow("encounter", sPath);
	wNew.setPosition(x,y);
	wNew.setSize(w,h);
	close();
end

function onLockChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	text.setReadOnly(bReadOnly);
end

