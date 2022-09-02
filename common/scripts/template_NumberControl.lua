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
local colorScrollerActive;
local colorInvalid;

local invalid = false;

-- Initialise the control

function onInit()
  if super and super.onInit then
    super.onInit();
  end
  -- font colours
  if fontcolor and fontcolor[1] then
    if fontcolor[1].readonly and fontcolor[1].readonly[1] then
      colorReadOnly = fontcolor[1].readonly[1];
    end
    
    if fontcolor[1].normal and fontcolor[1].normal[1] then
      colorNormal = fontcolor[1].normal[1];
    end
    
    if fontcolor[1].mousescroll and fontcolor[1].mousescroll[1] then
      colorScrollerActive = fontcolor[1].mousescroll[1];
    end
    
    if fontcolor[1].invalid and fontcolor[1].invalid[1] then
      colorInvalid = fontcolor[1].invalid[1];
    end
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
  return true;
end

function setInvalid(state)
  invalid = state;
  refreshFontColor();
  return true;
end

function isInvalid()
  return invalid;
end

-- Internal dynamic colouring function

function refreshFontColor()
  if isInvalid() and colorInvalid then
    setColor(colorInvalid);
  elseif isReadOnly() and colorReadOnly then
    setColor(colorReadOnly);
  else
    setColor(colorNormal);
  end
end

-- Implement new behaviours: Optional mouse scroller control

function onWheel(notches)
  if isReadOnly() then
    return false;
  end
  if isMouseScrollerActivated() then
    setValue(getValue()+notches);
    return true;
  else
    return false;
  end
end

function onHover(state)
  if state and not isReadOnly() then
    Input.onControl = controlPressed;
    Input.onShift = shiftPressed;
    Input.onAlt = altPressed;
  else
    Input.onControl = function() end;
    Input.onShift = function() end;
    Input.onAlt = function() end;
  end
  if state and isMouseScrollerActivated() and not isReadOnly() then
    setColor(colorScrollerActive);
  else
    refreshFontColor();
  end
end

function isMouseScrollerActivated()
  local key = PreferenceManager.load(Preferences.MouseScrollerKey.PrefName);

  if not key then
    return true;
  end
  
  if key == Preferences.MouseScrollerKey.None then
    return true;
  end
  
  if (key == Preferences.MouseScrollerKey.Ctrl and Input.isControlPressed() == true) 
  or (key == Preferences.MouseScrollerKey.Shift and Input.isShiftPressed()  == true) 
  or (key == Preferences.MouseScrollerKey.Alt and Input.isAltPressed()      == true) then 
    return true;
  else
    return false;
  end
end

function controlPressed(pressed)
  local activationKey = PreferenceManager.load(Preferences.MouseScrollerKey.PrefName);
  if not isReadOnly() and activationKey == Preferences.MouseScrollerKey.Ctrl then
    if pressed then
      setColor(colorScrollerActive);
    else
      refreshFontColor();
    end
  end
end

function shiftPressed(pressed)
  local activationKey = PreferenceManager.load(Preferences.MouseScrollerKey.PrefName);
  if not isReadOnly() and activationKey == Preferences.MouseScrollerKey.Shift then
    if pressed then
      setColor(colorScrollerActive);
    else
      refreshFontColor();
    end
  end
end

function altPressed(pressed)
  local activationKey = PreferenceManager.load(Preferences.MouseScrollerKey.PrefName);
  if not isReadOnly() and activationKey == Preferences.MouseScrollerKey.Alt then
    if pressed then
      setColor(colorScrollerActive);
    else
      refreshFontColor();
    end
  end
end
