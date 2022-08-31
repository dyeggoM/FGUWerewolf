-- This file is provided under the Open Game License version 1.0a
-- For more information on OGL and related issues, see 
--   http://www.wizards.com/d20

-- All producers of work derived from this definition are adviced to
-- familiarize themselves with the above license, and to take special
-- care in providing the definition of Product Identity (as specified
-- by the OGL) in their products.

-- Copyright 2009 SmiteWorks Ltd.

slots = {};

max = 0;
maxcols = 1;
countnode = nil;

function onDrag(button, x, y, dragdata)
  local desc = getName();
  if titlefield and titlefield[1] then
    desc = window[titlefield[1]].getValue();
  end
  if title and title[1] then
    desc = title[1];
  end
  dragdata.setType("number");
  dragdata.setNumberData(countnode.getValue());
  dragdata.setDescription(desc);
  return true;
end

local doubleclicked = false;
local oldvalue = 0;

function onClickDown(...)
  return true;
end

function onClickRelease(button, x, y)
  if doubleclicked then
    doubleclicked = false;
    countnode.setValue(oldvalue);
  else
    oldvalue = countnode.getValue();
    if button == 2 or Input.isControlPressed() then
      countnode.setValue(0);
    else
      if not getSlotState(x, y) then
        countnode.setValue(countnode.getValue() + 1);
      else
        countnode.setValue(countnode.getValue() - 1);
      end
      checkBounds();
    end
  end
  updateSlots();
  return true;
end

function onDoubleClick(...)
  if(PreferenceManager == nil) then
    return false
  end
  if PreferenceManager.load(Preferences.DblClickDots.PrefName)==Preferences.Yes then
    local desc = getName();
    if titlefield and titlefield[1] then
      desc = window[titlefield[1]].getValue();
    end
    if title and title[1] then
      desc = title[1];
    end
    ModifierStack.addSlot(desc, oldvalue);
    doubleclicked = true;
    return true;
  end
end

function getValue()
  return countnode.getValue();
end

function setValue(count)
  countnode.setValue(count);
  checkBounds();
end

function updateSlots()
  -- Clear
  for k, v in ipairs(slots) do
    v.destroy();
  end
  
  slots = {};

  -- Construct based on values
  local c = countnode.getValue();

  local col = 0;
  local row = 0;

  for i = 1, max do
    local widget = nil;

    if i <= c then
      widget = addBitmapWidget(stateicons[1].on[1]);
    else
      widget = addBitmapWidget(stateicons[1].off[1]);
    end

    local posx = spacing[1].horizontal[1] * (col+0.5);
    local posy = spacing[1].vertical[1] * (row+0.5);
    widget.setPosition("topleft", posx, posy);
    
    col = col + 1;
    if col >= maxcols then
      col = 0;
      row = row + 1;
    end
    
    slots[i] = widget;
  end
end

function getSlotState(x, y)
  local c = countnode.getValue();

  local col = 0;
  local row = 0;
  
  local state = false;

  for i = 1, max do
    local widget = nil;

    if i <= c then
      state = true;
    else
      state = false;
    end

    local posx = spacing[1].horizontal[1] * col;
    local posy = spacing[1].vertical[1] * row;

    if x > posx and x < posx + spacing[1].horizontal[1] and
       y > posy and y < posy + spacing[1].vertical[1] then
      return state;
    end
    
    col = col + 1;
    if col >= maxcols then
      col = 0;
      row = row + 1;
    end
  end
  
  return state;
end

function checkBounds()
  if countnode.getValue() > max then
    countnode.setValue(max);
  elseif countnode.getValue() < 0 then
    countnode.setValue(0);
  end
end

function onWheel(notches)
  if isMouseScrollerActivated() then
    countnode.setValue(countnode.getValue() + notches);
    checkBounds();
    updateSlots();
    return true;
  end
end

function onMenuSelection(...)
  countnode.setValue(0);
  updateSlots();
end

function onInit()
  local nodename = getName();
  local rows = 1;
  registerMenuItem("Clear", "erase", 4);
  
  max = tonumber(dots[1]);
  if source and source[1] then
    nodename = source[1];
  end
  
  rows = tonumber(rowcount[1]);
  if rows and max then
    maxcols = math.ceil(max/rows);
  end
  countnode = window.getDatabaseNode().getChild(nodename);
  if not countnode then
    countnode = window.getDatabaseNode().createChild(nodename,"number");
    countnode.setValue(tonumber(default[1]));
  end
  
  countnode.onUpdate = updateSlots;
  
  updateSlots();
end

function isMouseScrollerActivated()
  if PreferenceManager == nil then
    return false;
  end
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

