-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local ctrlBar = nil;
local sBarFillColor = "006600";

local bHealthBar = false;
local bUsageBar = false;
local bAutomaticText = true;
local sTextPrefix = "";

local sCurrentNodePath = nil;
local sUsedNodePath = nil;
local sMaxNodePath = nil;

local bUsedMode = false;
local nCurrent = 0;
local nMax = 0;

local _bParsed = false;
local _bInitialized = false;

function onInit()
	self.parse();
end
function onClose()
	self.removeHandlers();
end
function onFirstLayout()
	self.init();
end

function parse()
	if _bParsed then
		return;
	end
	_bParsed = true;

	if fillcolor and fillcolor[1] then
		sBarFillColor = fillcolor[1];
	end
	if source and source[1] then
		local node = window.getDatabaseNode();
		if node and source[1].max and source[1].max[1] and source[1].max[1] ~= "" then
			sMaxNodePath = DB.getPath(node, source[1].max[1]);
		end
		if node and source[1].current and source[1].current[1] and source[1].current[1] ~= "" then
			sCurrentNodePath = DB.getPath(node, source[1].current[1]);
		elseif node and source[1].used and source[1].used[1] and source[1].used[1] ~= "" then
			sUsedNodePath = DB.getPath(node, source[1].used[1]);
			bUsedMode = true;
		end
	end
	
	if healthbar then
		bHealthBar = true;
	elseif usagebar then
		bUsageBar = true;
	elseif noautotext then
		bAutomaticText = false;
	end

	if textprefix and textprefix[1] then
		if textprefix[1].text and textprefix[1].text[1] then
			sTextPrefix = textprefix[1].text[1];
		elseif textprefix[1].textres and textprefix[1].textres[1] then
			sTextPrefix = Interface.getString(textprefix[1].textres[1]);
		end
	end
end
function init()
	if _bInitialized then
		return;
	end
	_bInitialized = true;

	self.parse();

	self.addHandlers();
	
	if sMaxNodePath then
		self.setMax(DB.getValue(sMaxNodePath, 0), true);
	end
	if sCurrentNodePath then
		self.setValue(DB.getValue(sCurrentNodePath, 0), true);
	end
	if sUsedNodePath then
		self.setUsed(DB.getValue(sUsedNodePath, 0), true);
	end

	self.initFillControl();

	self.update();
end
function initFillControl()
	ctrlBar = window.createControl("progressbarfill", getName() .. "_fill");
end

function addHandlers()
	if sMaxNodePath then
		DB.addHandler(sMaxNodePath, "onUpdate", onMaxChanged);
	end
	if sCurrentNodePath then
		DB.addHandler(sCurrentNodePath, "onUpdate", onCurrentChanged);
	end
	if sUsedNodePath then
		DB.addHandler(sUsedNodePath, "onUpdate", onUsedChanged);
	end

	if bHealthBar then
		OptionsManager.registerCallback("BARC", update);
		OptionsManager.registerCallback("WNDC", update);
		if not Session.IsHost then
			OptionsManager.registerCallback("SHPC", update);
		end
	elseif bUsageBar then
		OptionsManager.registerCallback("BARC", update);
		if not Session.IsHost then
			OptionsManager.registerCallback("SHPC", update);
		end
	end
end
function removeHandlers()
	if sMaxNodePath then
		DB.removeHandler(sMaxNodePath, "onUpdate", onMaxChanged);
	end
	if sCurrentNodePath then
		DB.removeHandler(sCurrentNodePath, "onUpdate", onCurrentChanged);
	end
	if sUsedNodePath then
		DB.removeHandler(sUsedNodePath, "onUpdate", onUsedChanged);
	end

	if bHealthBar then
		OptionsManager.unregisterCallback("BARC", update);
		OptionsManager.unregisterCallback("WNDC", update);
		if not Session.IsHost then
			OptionsManager.unregisterCallback("SHPC", update);
		end
	elseif bUsageBar then
		OptionsManager.unregisterCallback("BARC", update);
		if not Session.IsHost then
			OptionsManager.unregisterCallback("SHPC", update);
		end
	end
end

function setSourceMax(vMax)
	local sNewMaxNodePath = self.resolveSource(vMax);
	if sNewMaxNodePath == sMaxNodePath then return; end
	
	if sMaxNodePath then
		DB.removeHandler(sMaxNodePath, "onUpdate", onMaxChanged);
	end
	sMaxNodePath = sNewMaxNodePath;
	if sMaxNodePath then
		DB.addHandler(sMaxNodePath, "onUpdate", onMaxChanged);
	end
	self.onMaxChanged();
end
function setSourceCurrent(vCurrent)
	local sNewCurrentNodePath = self.resolveSource(vCurrent);
	if sNewCurrentNodePath == sCurrentNodePath then return; end
	
	if sCurrentNodePath then
		DB.removeHandler(sCurrentNodePath, "onUpdate", onCurrentChanged);
	end
	if sUsedNodePath then
		DB.removeHandler(sUsedNodePath, "onUpdate", onUsedChanged);
	end
	sCurrentNodePath = sNewCurrentNodePath;
	sUsedNodePath = nil;
	bUsedMode = false;
	if sCurrentNodePath then
		DB.addHandler(sCurrentNodePath, "onUpdate", onCurrentChanged);
	end
	self.onCurrentChanged();
end
function setSourceUsed(vUsed)
	local sNewUsedNodePath = self.resolveSource(vUsed);
	if sNewUsedNodePath == sUsedNodePath then return; end
	
	if sCurrentNodePath then
		DB.removeHandler(sCurrentNodePath, "onUpdate", onCurrentChanged);
	end
	if sUsedNodePath then
		DB.removeHandler(sUsedNodePath, "onUpdate", onUsedChanged);
	end
	sUsedNodePath = sNewUsedNodePath;
	sCurrentNodePath = nil;
	bUsedMode = true;
	if sUsedNodePath then
		DB.addHandler(sUsedNodePath, "onUpdate", onUsedChanged);
	end
	self.onUsedChanged();
end
function resolveSource(vSource)
	if type(vSource) == "string" then
		return vSource;
	elseif type(vSource) == "databasenode" then
		return vSource.getPath();
	end
	return nil;
end

function setFillColor(sNewBarFillColor)
	sBarFillColor = sNewBarFillColor;
	self.update();
end
function setText(sText)
	self.setTooltipText(sText);
	if ctrlBar then
		ctrlBar.setTooltipText(sText);
	end
end
function setAutoText()
	local sText = "" .. self.getValue() .. " / " .. self.getMax();
	if (sTextPrefix or "") ~= "" then
		sText = sTextPrefix .. ": " .. sText;
	end
	self.setText(sText);
end

function onCurrentChanged() self.setValue(DB.getValue(sCurrentNodePath, 0)); end
function onUsedChanged() self.setUsed(DB.getValue(sUsedNodePath, 0)); end
function onMaxChanged() self.setMax(DB.getValue(sMaxNodePath, 0)); end
function setValue(nValue, bSkipUpdate)
	local nNewCurrent = math.max(math.min(nValue, nMax), 0);
	if nCurrent == nNewCurrent then return; end

	nCurrent = nNewCurrent;
	if self.onValueChanged then
		self.onValueChanged();
	end
	if not bSkipUpdate then
		self.update();
	end
end
function setUsed(nValue, bSkipUpdate) 
	self.setValue(nMax - nValue, bSkipUpdate); 
end
function setMax(nValue, bSkipUpdate)
	local nNewMax = math.max(nValue, 0);
	if nMax == nNewMax then return; end
	
	local nOriginalUsed = nMax - nCurrent;
	nMax = nNewMax;
	nCurrent = math.max(math.min(nCurrent, nMax), 0);
	if self.onValueChanged then
		self.onValueChanged();
	end
	if bUsedMode then
		self.setUsed(nOriginalUsed, true);
	end
	if not bSkipUpdate then
		self.update();
	end
end
function getValue() return nCurrent; end
function getUsed() return nMax - nCurrent; end
function getMax() return nMax; end
function getPercent() if nMax <= 0 then return 0; end return math.max(math.min(nCurrent / nMax, 1), 0); end

function update()
	if bHealthBar then
		sBarFillColor = ColorManager.getHealthColor(1 - getPercent(), true);
	elseif bUsageBar then
		sBarFillColor = ColorManager.getUsageColor(1 - getPercent(), true);
	end

	if not ctrlBar then return; end
	
	local w,h = getSize();
	if (h < 2) or (w < 2) then
		ctrlBar.setVisible(false);
	else
		ctrlBar.setVisible(true);
		
		local bHorizontal = (h < w);
		local bOffset;
		if reverse and reverse[1] then
			bOffset = bHorizontal;
		else
			bOffset = not bHorizontal;
		end
		
		local nPercent = self.getPercent();

		local sName = self.getName();
		local x,y = self.getPosition();
		local nFrom, nLen;
		if bHorizontal then
			nLen = math.floor(((w - 2) * nPercent) + 0.5);
			if bOffset then
				nFrom = (w - nLen) - 1;
			else
				nFrom = 1;
			end
			ctrlBar.setAnchor("left", sName, "left", "absolute", nFrom);
			ctrlBar.setAnchor("top", sName, "top", "absolute", 1);
			ctrlBar.setAnchor("right", sName, "right", "absolute", nFrom - (w - nLen));
			ctrlBar.setAnchor("bottom", sName, "bottom", "absolute", -1);
		else
			nLen = math.floor(((h - 2) * nPercent) + 0.5);
			if bOffset then
				nFrom = (h - nLen) - 1;
			else
				nFrom = 1;
			end
			ctrlBar.setAnchor("left", sName, "left", "absolute", 1);
			ctrlBar.setAnchor("top", sName, "top", "absolute", nFrom);
			ctrlBar.setAnchor("right", sName, "right", "absolute", -1);
			ctrlBar.setAnchor("bottom", sName, "bottom", "absolute", nFrom - (h - nLen));
		end
		
		ctrlBar.setBackColor(sBarFillColor);
		
		if bHealthBar then
			if Session.IsHost or OptionsManager.isOption("SHPC", "detailed") then
				self.setAutoText();
			else
				self.setText("");
			end
		elseif bUsageBar then
			if Session.IsHost or OptionsManager.isOption("SHPC", "detailed") then
				self.setAutoText();
			else
				self.setText("");
			end
		elseif bAutomaticText then
			self.setAutoText();
		end
	end
end
