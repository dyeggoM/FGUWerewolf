-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
-- Specialized Record Helper Functions
--

function showRecord(sRecordType, node)
	local sDisplayClass = LibraryData.getRecordDisplayClass(sRecordType);
	Interface.openWindow(sDisplayClass, node);	
end

function setDefaultToken(node)
	local sLetter = DB.getValue(node, "name", ""):match("^(%a)");
	if sLetter then
		DB.setValue(node, "token", "token", string.format("tokens/Medium/%s.png@Letter Tokens", sLetter:lower()));
	end
end

--
-- Support import modes
--

local _tImportModes = {};

function registerImportMode(sRecordType, sMode, sLabel, fn)
	ImportUtilityManager.unregisterImportMode(sRecordType, sMode);
	if not _tImportModes[sRecordType] then
		_tImportModes[sRecordType] = {};
	end
	table.insert(_tImportModes[sRecordType], { sMode = sMode, sLabel = sLabel, fn = fn });
end
function unregisterImportMode(sRecordType, sMode)
	if _tImportModes[sRecordType] then
		for k,v in ipairs(_tImportModes[sRecordType]) do
			if v.sMode == sMode then
				table.remove(_tImportModes[sRecordType], k);
				return;
			end
		end
	end
end
function getImportMode(sRecordType, sMode)
	if _tImportModes[sRecordType] then
		for k,v in ipairs(_tImportModes[sRecordType]) do
			if v.sMode == sMode then
				return v;
			end
		end
	end
	return nil;
end
function populateImportModes(sRecordType, cCombo)
	if cCombo then
		cCombo.clear();
		if _tImportModes[sRecordType] then
			for _,v in ipairs(_tImportModes[sRecordType]) do
				cCombo.add(v.sMode, v.sLabel);
			end
			if _tImportModes[sRecordType][1] then
				cCombo.setListValue(_tImportModes[sRecordType][1].sLabel);
			end
		end
	end
end

--
-- Specialized String Helper Functions
--

function case_insensitive_pattern(pattern)
	-- find an optional '%' (group 1) followed by any character (group 2)
	local p = pattern:gsub("(%%?)(.)", 
		function(percent, letter)
			if percent ~= "" or not letter:match("%a") then
				-- if the '%' matched, or `letter` is not a letter, return "as is"
				return percent .. letter
			else
				-- else, return a case-insensitive character class of the matched letter
				return string.format("[%s%s]", letter:lower(), letter:upper())
			end
		end
	);

	return p;
end

--
-- Specialized String Cleanup Functions
--

local _sOpenBracket = "&#60;";
local _sCloseBracket = "&#62;";

-- Call this to replace problematic UTF-8 characters that had encoding issues.
-- these are replaced with simple ASCII characters
function cleanUpText(s)
	if (s or "") == "" then
		return "";
	end
	
	local sResult = internalCleanUpCharacters(s);
	sResult = internalCleanUpCombineParagraphs(sResult);
	sResult = internalCleanUpHTML(sResult);
	sResult = internalCleanUpPar5EMarkup(sResult);
	return sResult;
end

-- Resolve and replace problematic escape characters
function internalCleanUpCharacters(s)
	-- replace angled quote with simple single quote (')
	s = s:gsub("&#821[67];", "'");
	-- replace angled double quotes with simple double quote (")
	s = s:gsub("&#822[01];", '"');
	-- replace em/en dash with simple dash (-)
	s = s:gsub("&#821[12];", "-");
	-- replace minus sign with simple dash (-)
	s = s:gsub("&#8722;", "-");
	-- replace non-breaking space with simple space ( )
	s = s:gsub("&#160;", ' ');

	-- replace encoded double quote with simple double quote (")
	s = s:gsub("&#34;", '"');

	-- &#10; line feed - replace with carriage-return instead
	s = s:gsub("&#10;", "&#13;");
	-- &#10; line feed (already escaped) - replace with carriage-return instead
	s = s:gsub("&#38;#10;", "&#13;");

	return s;
end

function internalCleanUpCombineParagraphs(s)
	-- Combine paragraphs whenever a new line starts with a lower case letter.
	return s:gsub("</p><p>(%l)", " %1");
end

function internalCleanUpHTML(s)
	-- Remove empty paragraph tags
	s = s:gsub("<p%s?/>", "");

	-- handle replacement of literal html tags that we support
	-- handle already escaped italics <i> tags
	s = replaceHTMLTag(s, "i", "<i>", "</i>", false);
	-- handle already escaped bold <b> tags
	s = replaceHTMLTag(s, "b", "<b>", "</b>", false);
	s = replaceHTMLTag(s, "strong", "<b>", "</b>", false);
	
	-- treat <h1> and <h2> tags as a header tag <h>
	s = replaceHTMLTag(s, "h1", "<h>", "</h>", true);
	s = replaceHTMLTag(s, "h2", "<h>", "</h>", true);
	-- treat <h3> thru <h5> tags as bold paragraphs.
	s = replaceHTMLTag(s, "h3", "<b>", "</b>", false);
	s = replaceHTMLTag(s, "h4", "<b>", "</b>", false);
	s = replaceHTMLTag(s, "h5", "<b>", "</b>", false);
	-- recognize table tags 
	s = replaceHTMLTag(s, "table", "<table>", "</table>",true);
	s = replaceHTMLTag(s, "thead", "", "", true);
	s = stripHTMLTag(s, "caption", "", "", true);
	s = replaceHTMLTag(s, "tbody", "", "", true)
	s = replaceHTMLTag(s, "tr", "<tr>", "</tr>", true);
	s = replaceHTMLTag(s, "td", "<td%1>", "</td>", true);
	s = replaceHTMLTag(s, "th", "<td%1><b>", "</b></td>", true);
		
	-- recognize lists
	s = replaceHTMLTag(s, "ul", "<list>", "</list>",true);
	s = replaceHTMLTag(s, "ol", "<list>", "</list>",true);
	s = replaceHTMLTag(s, "li", "<li>", "</li>",true);
	
	-- remove literal paragraph tags because they are already embedded
	-- useful for anyone who copies and pastes View Source from a web page
	s = replaceHTMLTag(s, "p", "", "", false);
	
	-- Strip hyperlinks
	s = replaceHTMLTag(s, "a", "", "", false);

	-- Look for and remove extra paragraph tags that remain.
	s = s:gsub("<p><h>", "<h>");
	s = s:gsub("</h></p>", "</h>");
	s = s:gsub("<p><tr>", "<tr>");
	s = s:gsub("</tr></p>", "</tr>");
	s = s:gsub("<p><table>", "<table>");
	s = s:gsub("</table></p>", "</table>");
	s = s:gsub("<p><td>", "<td>");
	s = s:gsub("</td></p>", "</td>");
	s = s:gsub("<td><p>", "<td>");
	s = s:gsub("</p></td>", "</td>");	
	s = s:gsub("<p><list>", "<list>");
	s = s:gsub("</list></p>", "</list>");
	s = s:gsub("<p><li>", "<li>");
	s = s:gsub("</li></p>", "</li>");

	return s;
end

function internalCleanUpPar5EMarkup(s)
	s = convertPAR5ETables(s);
	s = convertPAR5ELists(s);
	s = convertPAR5EParagraphs(s);
	s = convertPAR5EHeaders(s);
	s = convertPAR5EParagraphLeadins(s);
	return s;
end

-- LUA does not support optional groups, so we have to look for every permutation of a preceding <p> tag,
-- a trailing </p> tag, the absence of those, or the combination of both.
-- Use a %1 within the Open Replacement to indicate where the optional tag parameters should be placed.
function replaceHTMLTag(s, inTag, inOpenReplacement, inCloseReplacement, bStripParagraph)
	local sResult = s;
	local sTag = case_insensitive_pattern(inTag:lower());
	local sCleanOpenReplacement = inOpenReplacement:gsub("[%][1]","");
	
	-- Start with the most combinations of extraneous tags and replace each permutation of surrounding <p> tags
	if bStripParagraph then
		-- first replace the opening tag
		local sPattern = "<p>%s*" .. _sOpenBracket .. sTag .. _sCloseBracket .. "%s*</p>"; 
		sResult = sResult:gsub(sPattern, sCleanOpenReplacement);
		-- look for version not wrapped in paragraph tags
		sPattern = _sOpenBracket .. sTag .. _sCloseBracket;
		sResult = sResult:gsub(sPattern, sCleanOpenReplacement);
		
		-- second pass: replace opening tags that include optional parameters
		sPattern = "<p>%s*" .. _sOpenBracket .. sTag .. "(.-)" .. _sCloseBracket .. "%s*</p>"; 
		sResult = sResult:gsub(sPattern, inOpenReplacement);
		-- look for version not wrapped in paragraph tags
		sPattern = _sOpenBracket .. sTag .. "(.-)" .. _sCloseBracket;
		sResult = sResult:gsub(sPattern, inOpenReplacement);
		
		-- next replace the closing tag
		sPattern = "<p>%s*" .. _sOpenBracket .. "/" .. sTag .. _sCloseBracket .. "%s*</p>";
		sResult = sResult:gsub(sPattern, inCloseReplacement);
		sPattern = _sOpenBracket .. "/"  .. sTag .. _sCloseBracket;
		sResult = sResult:gsub(sPattern, inCloseReplacement);

	-- Just do a simple case-insensitive replacement
	else
		-- first replace the opening tag
		local sPattern = _sOpenBracket .. sTag .. "(.-)" .. _sCloseBracket;
		sResult = sResult:gsub(sPattern,inOpenReplacement);		
		
		-- next replace the closing tag
		sPattern = _sOpenBracket .. "/" .. sTag .. _sCloseBracket;
		sResult = sResult:gsub(sPattern,inCloseReplacement);		
	end
	
	return sResult;
end

-- Works the same way as replaceHTMLTag, except the open and close brackets are not escaped into XML
function replaceFGTag(s, inTag, inOpenReplacement, inCloseReplacement, bStripParagraph)
	local sResult = s;
	local sTag = case_insensitive_pattern(inTag:lower());
	local sCleanOpenReplacement = inOpenReplacement:gsub("[%][1]", "");
	
	-- Start with the most combinations of extraneous tags and replace each permutation of surrounding <p> tags
	if bStripParagraph then
		-- first replace the opening tag
		local sPattern = "<p>%s*<" .. sTag .. ">%s*</p>"; 
		sResult = sResult:gsub(sPattern, sCleanOpenReplacement);
		-- look for version not wrapped in paragraph tags
		sPattern = "<" .. sTag .. ">";
		sResult = sResult:gsub(sPattern, sCleanOpenReplacement);
		
		-- second pass: replace opening tags that include optional parameters
		sPattern = "<p>%s*<" .. sTag .. "(.-)>%s*</p>"; 
		sResult = sResult:gsub(sPattern, inOpenReplacement);
		-- look for version not wrapped in paragraph tags
		sPattern = "<" .. sTag .. "(.-)>";
		sResult = sResult:gsub(sPattern, inOpenReplacement);
		
		-- next replace the closing tag
		sPattern = "<p>%s*</" .. sTag .. ">%s*</p>";
		sResult = sResult:gsub(sPattern, inCloseReplacement);
		sPattern = "</"  .. sTag .. ">";
		sResult = sResult:gsub(sPattern, inCloseReplacement);

	-- Just do a simple case-insensitive replacement
	else
		-- first replace the opening tag
		local sPattern = "<" .. sTag .. "(.-)>";
		sResult = sResult:gsub(sPattern, inOpenReplacement);		
		
		-- next replace the closing tag
		sPattern = "</" .. sTag .. ">";
		sResult = sResult:gsub(sPattern, inCloseReplacement);		
	end
	
	return sResult;
end

-- This function removes everything between the open and close of the specified tag
-- LUA does not support optional groups, so we have to look for every permutation of a preceding <p> tag,
-- a trailing </p> tag, the absence of those, or the combination of both.
function stripHTMLTag(s, inTag, inOpenReplacement, inCloseReplacement, bStripParagraph)
	local sResult = s;
	local sTag = case_insensitive_pattern(inTag:lower());
	
	-- Start with the most combinations of extraneous tags and replace each permutation of surrounding <p> tags
	if bStripParagraph then
		-- remove anything within and including teh opening and closing tags
		local sPattern = _sOpenBracket .. sTag .. "(.-)" .. _sCloseBracket .. "(.-)" .. _sOpenBracket .. "/" .. sTag .. _sCloseBracket;
		-- replace the entire contents with a simple search and replace string so we can look for surrounding
		-- paragraphs more easily after the middle content has been replaced
		sResult = sResult:gsub(sPattern, "XREMOVEX");

		-- now you can safely remove all instances where the paragraphs tags are next to these replaced values
		sPattern = "<p>XREMOVEX</p>";
		sResult = sResult:gsub(sPattern, "");
		sPattern = "<p>XREMOVEX";
		sResult = sResult:gsub(sPattern, "");		
		sPattern = "XREMOVEX</p>";
		sResult = sResult:gsub(sPattern, "");
		sPattern = "XREMOVEX";
		sResult = sResult:gsub(sPattern, "");

	-- Just do a simple case-insensitive replacement
	else
		local sPattern = _sOpenBracket .. sTag .. "(.-)" .. _sCloseBracket .. "(.-)" .. _sOpenBracket .. "/" .. sTag .. _sCloseBracket;
		sResult = sResult:gsub(sPattern, "");
	end
	
	return sResult;
end

-- Calls the convertPAR5ETable function until there are no more tables found
function convertPAR5ETables(s)
	local sResult = s;
	local sLastSource = "-";
	
	-- keep looping as long as there are changes
	while sResult ~= sLastSource do
		sLastSource = sResult;
		sResult = convertPAR5ETable(sResult);
	end
	
	return sResult;
end

-- This translates PAR5E style tables into formatted text tables
-- Example:
-- #ts;
-- #th;Size;Space;Examples;
-- #tr;Tiny;2½ by 2½ ft.;Imp, sprite
-- #tr;Small;5 by 5 ft.;Giant rat, goblin
-- #tr;Medium;5 by 5 ft.;Orc, werewolf
-- #tr;Large;10 by 10 ft.;Hippogriff, ogre
-- #tr;Huge;15 by 15 ft.;Fire giant, treant
-- #tr;Gargantuan;20 by 20 ft. or larger;Kraken, purple worm
-- #te;	
function convertPAR5ETable(s)
	-- patterns to use for searching
	local ts = "<p>#ts;</p>";
	local te = "<p>#te;</p>";
	
	-- look for the start and the immediate end of the table tags and grab the middle
	local iTableStart, iTableEnd = s:find(ts .. ".-" .. te, 1);
	if not iTableEnd then
		return s;
	end

	-- save the part before the table
	local tResult = {};
	table.insert(tResult, s:sub(1, iTableStart - 1));
	
	-- parse out the table
	table.insert(tResult, "<table>");
	
	local inTable = s:sub(iTableStart,iTableEnd);
	local sRowPattern = "<p>#t[hr];.-</p>";
	local iRowStart, iRowEnd = inTable:find(sRowPattern);
	while iRowEnd do
		local rowType = inTable:sub(iRowStart + 4, iRowStart + 5) or "";
		local sRow = inTable:sub(iRowStart + 7, iRowEnd - 4) or "";
		
		table.insert(tResult, "<tr>");
		
		local tSegments = StringManager.splitByPattern(sRow, ";", true);
		for _,cellValue in ipairs(tSegments) do
			-- Handle optional colspan values. These are prefixes
			-- Example: 2:Double cell;4:Quadruple cell;Single cell
			local colSpan;
			iColSpanStart, iColSpanEnd = cellValue:find(":");
			if iColSpanEnd then
				colSpan = cellValue:sub(1, iColSpanStart - 1);
				cellValue = cellValue:sub(iColSpanStart + 1);
			else
				colSpan = "1";
			end
			
			if rowType == "th" then
			   cellValue = string.format("<b>%s</b>", cellValue);
			end
			
			if colSpan == "1" then
				table.insert(tResult, string.format("<td>%s</td>", cellValue));
			else
				table.insert(tResult, string.format("<td colspan='%s'>%s</td>", colSpan, cellValue));
			end
		end
		
		table.insert(tResult, "</tr>");

		iRowStart, iRowEnd = inTable:find(sRowPattern, iRowStart + 1);
	end
	
	table.insert(tResult, "</table>");
	
	-- save the remainder of the description after the table
	table.insert(tResult, s:sub(iTableEnd+1));
			
	return table.concat(tResult);
end

-- calls the convertPAR5EList function until there are no more lists
-- found to parse.
function convertPAR5ELists(s)
	local sResult = s;
	local sLastSource = "-";
	
	-- keep looping as long as there are changes
	while sResult ~= sLastSource do
		sLastSource = sResult;
		sResult = convertPAR5EList(sResult);
	end
	
	return sResult;
end

-- This translates PAR5E style lists into formatted text lists
-- Example:
--#ls;
--#li;An orange
--#li;An apple
--#li;A banana
--#le;
function convertPAR5EList(s)
	-- patterns to use for searching
	local ls = "<p>#ls;</p>";
	local le = "<p>#le;</p>";
	
	-- look for the start and immediate end of a list tags. Grab everything in the middle
	local iListStart, iListEnd = s:find(ls .. ".-" .. le, 1);
	if not iListEnd then
		return s;
	end

	-- save the part before the list
	local tResult = {};
	table.insert(tResult, s:sub(1, iListStart - 1));
	
	-- parse out the list
	table.insert(tResult, "<list>");
	
	local inList = s:sub(iListStart, iListEnd);
	local sListItemPattern = "<p>#li;.-</p>";
	local iListItemStart, iListItemEnd = inList:find(sListItemPattern);
	while iListItemEnd do
		local sListItem = inList:sub(iListItemStart + 7,iListItemEnd - 4);
		table.insert(tResult, string.format("<li>%s</li>", sListItem));

		iListItemStart, iListItemEnd = inList:find(sListItemPattern, iListItemStart + 1);
	end
	
	table.insert(tResult, "</list>");
	
	-- save the remainder of the description after the list
	table.insert(tResult, s:sub(iListEnd + 1));
			
	return table.concat(tResult);
end

-- This translates PAR5E style lead-ins for paragraphs
-- Examples:
--#bs;Apples: A healthy snack choice
--#bs;Apples. Still a healthy choice
--#is;Oranges. They can use period or colon to separate
--#bis;Mango: They are so special that they get bold and italic treatment.
function convertPAR5EParagraphLeadins(s)
	-- patterns to use for searching. 0 or more b or i characters, followed by an s
	-- within opening and closing paragraph <p> tags.
	local sPattern = "<p>#b?i?s;.-</p>";
	
	-- look for the start and immediate end of a list tags. Grab everything in the middle
	local iParagraphStart, iParagraphEnd = s:find(sPattern);
	if not iParagraphEnd then
		return s;
	end

	-- parse out the middle of the paragraph
	local tResult = {};
	local iLastParagraphEnd = 0;
	while iParagraphEnd do
		-- save the part before the list
		if (iParagraphStart - 1) > (iLastParagraphEnd + 1) then
			table.insert(tResult, s:sub(iLastParagraphEnd + 1, iParagraphStart - 1));
		end

		-- grab everything after the opening <p> tag and up to the closing </p> tag
		local inParagraph = s:sub(iParagraphStart + 3, iParagraphEnd - 4);
		
		-- split off the PAR5E tag
		local iSemicolonLocation = inParagraph:find(";");	
		local iLeadinBreakLocation = inParagraph:find("[.:-]", iSemicolonLocation + 1);
		local paragraphType = inParagraph:sub(1, iSemicolonLocation);
		
		-- grab the leadin phrase, including the semicolon/period/dash.
		local sLeadin = inParagraph:sub(iSemicolonLocation + 1, iLeadinBreakLocation);
		local sParagraphEnd = inParagraph:sub(iLeadinBreakLocation + 1);			
					
		local sLeadinBeginTag = "";
		local sLeadinEndTag = "";
		if paragraphType:match("b", 1) then
			sLeadinBeginTag = "<b>";
			sLeadinEndTag = "</b>";
		end
		if paragraphType:match("i", 1) then
			sLeadinBeginTag = sLeadinBeginTag .. "<i>";
			sLeadinEndTag = "</i>" .. sLeadinEndTag;
		end
		
		sLeadin = sLeadinBeginTag .. sLeadin .. sLeadinEndTag;
		table.insert(tResult, string.format("<p>%s%s</p>", sLeadin, sParagraphEnd));

		iLastParagraphEnd = iParagraphEnd;
		iParagraphStart, iParagraphEnd = s:find(sPattern, iParagraphEnd + 1);			
	end
	
	-- save the final part of the formatted text, after all paragraph tags have been
	-- processed. First, compare the last postion of a paragraph with the length of the
	-- source string.
	if #s > iLastParagraphEnd then
		table.insert(tResult, s:sub(iLastParagraphEnd + 1));
	end
			
	return table.concat(tResult);
end

-- This translates PAR5E style lists into formatted text lists
-- Examples:
--#bp;Bold this entire paragraph
--#ip;Italicize this entire paragraph
function convertPAR5EParagraphs(s)
	-- patterns to use for searching
	local sPattern = "<p>#[bi]p;.-</p>";
	
	-- look for the start and immediate end of a list tags. Grab everything in the middle
	local iParagraphStart, iParagraphEnd = s:find(sPattern);
	if not iParagraphEnd then
		return s;
	end

	-- parse out the middle of the paragraph
	local tResult = {};
	local iLastParagraphEnd = 0;
	while iParagraphEnd do
		-- save the part before the list
		if (iParagraphStart - 1) > (iLastParagraphEnd + 1) then
			table.insert(tResult, s:sub(iLastParagraphEnd + 1, iParagraphStart - 1));
		end

		local inParagraph = s:sub(iParagraphStart + 7, iParagraphEnd - 4);
		local paragraphType = s:sub(iParagraphStart + 4, iParagraphStart + 4);
		table.insert(tResult, string.format("<p><%s>%s</%s></p>", paragraphType, inParagraph, paragraphType));

		iLastParagraphEnd = iParagraphEnd;
		iParagraphStart, iParagraphEnd = s:find(sPattern, iParagraphEnd + 1);			
	end
	
	-- save the final part of the formatted text, after all paragraph tags have been
	-- processed. First, compare the last postion of a paragraph with the length of the
	-- source string.
	if #s > iLastParagraphEnd then
		table.insert(tResult, s:sub(iLastParagraphEnd + 1));
	end
			
	return table.concat(tResult);
end

-- This translates PAR5E style lists into formatted text lists
-- Examples:
--#h;Chapter 1: Building a Character
function convertPAR5EHeaders(s)
	-- patterns to use for searching
	local sPattern = "<p>#h;.-</p>";
	
	-- look for the start and immediate end of a list tags. Grab everything in the middle
	local iParagraphStart, iParagraphEnd = s:find(sPattern);
	if not iParagraphEnd then
		return s;
	end

	-- parse out the middle of the paragraph
	local tResult = {};
	local iLastParagraphEnd = 0;
	while iParagraphEnd do
		-- save the part before the list
		if (iParagraphStart - 1) > (iLastParagraphEnd + 1) then
			table.insert(tResult, s:sub(iLastParagraphEnd + 1, iParagraphStart - 1));
		end
		
		table.insert(tResult, string.format("<h>%s</h>", s:sub(iParagraphStart + 6, iParagraphEnd - 4)));
		
		iLastParagraphEnd = iParagraphEnd;
		iParagraphStart, iParagraphEnd = s:find(sPattern, iParagraphEnd + 1);			
	end
	
	-- save the final part of the formatted text, after all paragraph tags have been
	-- processed. First, compare the last postion of a paragraph with the length of the
	-- source string.
	if #s > iLastParagraphEnd then
		table.insert(tResult, s:sub(iLastParagraphEnd + 1));
	end
			
	return table.concat(tResult);
end

--
-- Specialized String Parsing/Tokenizing Functions
--

-- read in the source and write out a single line to each row of a table. Look for 
-- all end tags. If you find an end tag that represents the end of a section, save this as 
-- a row in the table that you return. Examples of end tags we want to capture as a "line" 
-- are headers <h> tags, paragraph <p> tags, list tags <list>, <frame> tags, or <table> tags
function parseFormattedTextToLines(s)
	-- Split into lines, based on ending tags for formatted text in FG
	local sSplitPattern = "</.->";
	local tEndTags = {"h", "p", "list", "linklist", "frame", "table"};

	local tResults = {};
	local sRow = "";
	local sLastRow = "";
	local iStart = 1;
	local iSplitStart, iSplitEnd = s:find(sSplitPattern);
	while iSplitStart do
		local sTag = s:sub(iSplitStart + 2, iSplitEnd - 1);
		
		-- see if this is a tag that we will ignore
		if not StringManager.contains(tEndTags, sTag) then
			-- this tag is not an end tag. Save the results and keep parsing
			sRow = sLastRow .. s:sub(iStart, iSplitEnd);
			sLastRow = sRow;

		else
			-- this is an end tag. Strip the tag and save the processed text as a new "line"
			sRow = s:sub(iStart, iSplitStart - 1);
			sRow = sLastRow .. sRow;
			
			-- remove the leading tag
			sRow = sRow:gsub("^<" .. sTag .. ">", "");
			sLastRow = "";
	
			table.insert(tResults, sRow);
		end
		
		iStart = iSplitEnd + 1;					
		iSplitStart, iSplitEnd = s:find(sSplitPattern, iStart);
	end
	
	-- After processing, save whatever is left in the string to the final row.
	sRow = sLastRow .. s:sub(iStart);
	table.insert(tResults, sRow);

	return tResults;
end
