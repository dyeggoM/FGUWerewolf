-- This file is provided under the Open Game License version 1.0a
-- For more information on OGL and related issues, see 
--   http://www.wizards.com/d20

-- All producers of work derived from this definition are adviced to
-- familiarize themselves with the above license, and to take special
-- care in providing the definition of Product Identity (as specified
-- by the OGL) in their products.

-- Copyright 2009 SmiteWorks Ltd.

local colorReadOnly;
local colorNormal;
local colorInvalid;

local invalid = false;
local matchstring = "%s*(%-?%d*)%s*,?%s*(%-?%d*)%s*,?%s*(%-?%d*)%s*,?%s*(%-?%d*)%s*";

local normalframe = {name=nil,parms="",left=0,top=0,right=0,bottom=0};
local focusframe  = {name=nil,parms="",left=0,top=0,right=0,bottom=0};

-- Initialise the control

function onInit()
  if super and super.onInit then
    super.onInit();
  end
  -- get default font colour from the <color> element, if present
  if color and color[1] then
    colorNormal = color[1];
  end
  -- font colours
  if fontcolor and fontcolor[1] then
    if fontcolor[1].normal and fontcolor[1].normal[1] then
      colorNormal = fontcolor[1].normal[1];
    end
    
    if fontcolor[1].readonly and fontcolor[1].readonly[1] then
      colorReadOnly = fontcolor[1].readonly[1];
    else
      colorReadOnly = colorNormal;
    end
    
    if fontcolor[1].invalid  and fontcolor[1].invalid[1] then
      colorInvalid = fontcolor[1].invalid[1];
    else
      colorInvalid = colorNormal;
    end
  end
  -- control frame
  if frame and frame[1] then
    if frame[1].name then
      normalframe.name = frame[1].name[1];
    end
    if frame[1].offset and frame[1].offset[1] then
      normalframe.parms = frame[1].offset[1];
      local left, top, right, bottom = string.match(normalframe.parms,matchstring);
      normalframe.left = tonumber(left) or 0;
      normalframe.top = tonumber(top) or 0;
      normalframe.right = tonumber(right) or 0;
      normalframe.bottom = tonumber(bottom) or 0;
    end
  end
  -- key edit (focus) frame
  if keyeditframe and keyeditframe[1] then
    if keyeditframe[1].name then
      focusframe.name = keyeditframe[1].name[1];
    end
    if keyeditframe[1].offset and keyeditframe[1].offset[1] then
      focusframe.parms = keyeditframe[1].offset[1];
      local left, top, right, bottom = string.match(focusframe.parms,matchstring);
      focusframe.left = tonumber(left) or 0;
      focusframe.top = tonumber(top) or 0;
      focusframe.right = tonumber(right) or 0;
      focusframe.bottom = tonumber(bottom) or 0;
    end
  else
    focusframe.name = normalframe.name;
    focusframe.parms = normalframe.parms;
    focusframe.left = normalframe.left;
    focusframe.top = normalframe.top;
    focusframe.right = normalframe.right;
    focusframe.bottom = normalframe.bottom;
  end
  refreshFontColor();
end

-- Extend control for dynamic colouring

function setVisible(state)
  if super and super.setVisible then
    super.setVisible(state);
  end
  refreshFontColor();
  return true;
end

function setEnabled(state)
  if super and super.setEnabled then
    super.setEnabled(state);
  end
  refreshFontColor();
  return true;
end

function setReadOnly(state)
  if super and super.setReadOnly then
    super.setReadOnly(state);
  end
  refreshFontColor();
end

function setInvalid(state)
  invalid = state;
  refreshFontColor();
end

function isInvalid()
  return invalid;
end

-- Internal dynamic colouring function

function refreshFontColor()
  if invalid then
    setColor(colorInvalid);
  else
    if isReadOnly() == true then
      setColor(colorReadOnly);
    else
      setColor(colorNormal);
    end
  end
end

-- Implement new behaviours: Key Edit Frame

function onLoseFocus()
  if super and super.onLoseFocus then
    super.onLoseFocus();
  end
  print(focusframe.name)
  setFrame(normalframe.name, normalframe.left, normalframe.top, normalframe.right, normalframe.bottom);
end

function onGainFocus()
  if super and super.onGainFocus then
    super.onGainFocus();
  end
  setFrame(focusframe.name, focusframe.left, focusframe.top, focusframe.right, focusframe.bottom);
end
