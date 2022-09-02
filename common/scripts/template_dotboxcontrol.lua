-- This file is provided under the Open Game License version 1.0a
-- For more information on OGL and related issues, see 
--   http://www.wizards.com/d20

-- All producers of work derived from this definition are adviced to
-- familiarize themselves with the above license, and to take special
-- care in providing the definition of Product Identity (as specified
-- by the OGL) in their products.

-- Copyright 2009 SmiteWorks Ltd.

dotwidgets  = {};
boxwidgets = {};

max = 0;
maxdegree = 0;

countnode = nil;
slashnode = nil;
crossnode = nil;
starnode  = nil;

hidedots = false;

local busy = false;
local pending = false;

function updated()
  pending = true;
  if not busy then
    busy = true;
    while pending do
      pending = false;
      updateSlots();
    end
  end
  busy = false;
end

function updateSlots()
  local d, s, c, x;
  
  -- Clear
  for k, v in ipairs(dotwidgets) do
    v.destroy();
  end
  for k, v in ipairs(boxwidgets) do
    v.destroy();
  end
  
  dotwidgets = {};
  boxwidgets = {};

  -- Check values within bounds
  d = countnode.getValue();
  if d<0 then
    d = 0;
  end
  if slashnode then
    s = slashnode.getValue();
    if (maxdegree<1 and s~=0) or s<0 then
      s = 0;
      slashnode.setValue(0);
    end
  else
    s = 0;
  end
  if crossnode then
    c = crossnode.getValue();
    if (maxdegree<2 and c~=0) or c<0 then
      c = 0;
      crossnode.setValue(0);
    end
  else
    c = 0;
  end
  if starnode then
    x = starnode.getValue();
    if (maxdegree<3 and x~=0) or x<0 then
      x = 0;
      starnode.setValue(0);
    end
  else
    x = 0;
  end
  
  -- Implement rules
  if x>d then
    x = d;
    starnode.setValue(x);
  end
  if x+c>d then
    c = d-x;
    crossnode.setValue(c);
  end
  if x+c+s>d then
    s = d-(x+c);
    slashnode.setValue(s);
  end

  -- Construct dots based on values
  if not hidedots then
    for i = 1, max do
      local widget = nil;

      if i <= d then
        widget = addBitmapWidget(doticons[1].on[1]);
      else
        widget = addBitmapWidget(doticons[1].off[1]);
      end

      local posx = spacing[1].horizontal[1] * (i - 0.5);
      local posy = spacing[1].vertical[1] * 0.5;
      widget.setPosition("topleft", posx, posy);
      
      dotwidgets[i] = widget;
    end
  end
  
  for i = 1, max do
    local widget = nil;

    if i <= x then
      widget = addBitmapWidget(boxicons[1].star[1]);
    elseif i<= (x + c) then
      widget = addBitmapWidget(boxicons[1].cross[1]);
    elseif i<= (x + c + s) then
      widget = addBitmapWidget(boxicons[1].slash[1]);
    else
      widget = addBitmapWidget(boxicons[1].empty[1]);
    end
    
    if i>d then
      widget.setColor("3fffffff");
    end

    local posx = spacing[1].horizontal[1] * (i - 0.5);
    local posy = spacing[1].vertical[1] * 1.5;
    if hidedots then
      posy = spacing[1].vertical[1] * 0.5;
    end
    widget.setPosition("topleft", posx, posy);
    
    boxwidgets[i] = widget;
  end
  busy = false;
end

function getSlotState(x, y)
  local index = 0;
  local counter = true;
  local d = countnode.getValue();

  if hidedots or (y > tonumber(spacing[1].vertical[1])) then
    counter = false;
  end
  for i = 1, max do
    local posx = spacing[1].horizontal[1] * (i - 1);
    if x > posx and x < posx + spacing[1].horizontal[1] then
      index = i;
    end
  end
  
  if counter then
    return (index>1) and (index<=d);
  else
    local s, c, x;
    if slashnode then
      s = slashnode.getValue();
    else
      s = 0;
    end
    if crossnode then
      c = crossnode.getValue();
    else
      c = 0;
    end
    if starnode then
      x = starnode.getValue();
    else
      x = 0;
    end
    -- need to check what state is at index position
    if index<1 then
      return 0;
    elseif index<=x then
      return 3;
    elseif index<=(x+c) then
      return 2;
    elseif index<=(x+c+s) then
      return 1;
    elseif index>d then
      return -1;
    else
      return 0;
    end
  end
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
    local oldval = countnode.getValue();
    local newval = oldval + notches;
    if newval > max then
      newval = max;
    elseif newval < 0 then
      newval = 0;
    end
    if oldval~=newval then
      countnode.setValue(newval);
    end
    return true;
  end
end

function onClickDown(button, x, y)
  return true;
end

function onClickRelease(button, x, y)
  if (button == 2 or Input.isControlPressed()) and (countnode.getValue()~=0) then
    countnode.setValue(0);
  else
    local state = getSlotState(x, y);
    if type(state)=="boolean" then
      -- clicked the top row (dots)
      if state then
        countnode.setValue(countnode.getValue() - 1);
      else
        countnode.setValue(countnode.getValue() + 1);
      end
    else
      -- clicked the bottom row (boxes)
      if state==1 then
        slashnode.setValue(slashnode.getValue() - 1);
        if crossnode then
          crossnode.setValue(crossnode.getValue() + 1);
        end
      elseif state==2 then
        crossnode.setValue(crossnode.getValue() - 1);
        if starnode then
          starnode.setValue(starnode.getValue() + 1);
        end
      elseif state==3 then
        starnode.setValue(starnode.getValue() - 1);
      elseif state==-1 then
        -- do nothing
      elseif slashnode then
        slashnode.setValue(slashnode.getValue() + 1);
      end
    end
    checkBounds();
  end
  return true;
end

function onMenuSelection(...)
  countnode.setValue(0);
end

function setSource(node)
  local slashname, crossname, starname;

  slashname = nodenames[1].slash[1];
  crossname = nodenames[1].cross[1];
  starname = nodenames[1].star[1];

  if not node then
print("node not found");
    return;
  end
  
  countnode = node.createChild("dots","number");
  
  if maxdegree>=1 then
    slashnode = node.createChild(slashname,"number");
  end
  if maxdegree>=2 then
    crossnode = node.createChild(crossname,"number");
  end
  if maxdegree>=3 then
    starnode = node.createChild(starname,"number");
  end
  
  node.onChildUpdate = updated;
  
  updateSlots();
end

function onInit()
  local nodename = getName();
  local node = "";
  
  if nodots then
    hidedots = true;
  end
  
  if not hidedots then
    registerMenuItem("Clear", "erase", 4);
  end
  
  max = tonumber(dots[1]);
  maxdegree = tonumber(degree[1]);
  
  if source and source[1] then
    nodename = source[1];
  end
  
  node = window.getDatabaseNode().createChild(nodename);
  
  setSource(node);
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
