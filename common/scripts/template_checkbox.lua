-- This file is provided under the Open Game License version 1.0a
-- For more information on OGL and related issues, see 
--   http://www.wizards.com/d20

-- All producers of work derived from this definition are adviced to
-- familiarize themselves with the above license, and to take special
-- care in providing the definition of Product Identity (as specified
-- by the OGL) in their products.

-- Copyright 2009 SmiteWorks Ltd.

-- The sourceless value is used if the checkbox is used in a window not bound to the database
-- or if the <sourceless /> flag is specifically set

local sourcelessvalue = false;
local readonlyvalue = false;
local sourcenodename = "";

function setState(state)
  local datavalue = 1;
  
  if state == nil or state == false or state == 0 then
    datavalue = 0;
  end
  
  if source then
    source.setValue(datavalue);
  else
    if datavalue == 0 then
      sourcelessvalue = false;
    else
      sourcelessvalue = true;
    end
    
    update();
  end
end

function update()
  if source then
    if source.getValue() ~= 0 then
      setIcon(stateicons[1].on[1]);
    else
      setIcon(stateicons[1].off[1]);
    end
  else
    if sourcelessvalue then
      setIcon(stateicons[1].on[1]);
    else
      setIcon(stateicons[1].off[1]);
    end
  end
  
  if self.onValueChanged then
    self.onValueChanged();
  end
end

function isReadOnly()
  return readonlyvalue;
end

function setReadOnly(state)
  if getDatabaseNode() and getDatabaseNode().isStatic() then
    return;
  end
  if state then
    readonlyvalue = true;
  else
    readonlyvalue = false;
  end
end

function getState()
  if source then
    local datavalue = source.getValue();
    return datavalue ~= 0;
  else
    return sourcelessvalue;
  end
end

function onClickDown(button, x, y)
  if readonlyvalue then
    return;
  end
  setState(not getState());
end

function onInit()
  setIcon(stateicons[1].off[1]);

  if not sourceless and window.getDatabaseNode() then
    -- Get value from source node
    if sourcename then
      sourcenodename = sourcename[1];
    else
      sourcenodename = getName();
    end
    window.getDatabaseNode().onChildUpdate = capture;
    capture();
  else
    -- Use internal value, initialize to checked if <checked /> is specified
    if checked then
      sourcelessvalue = true;
      update();
    end
  end
  
  if readonly then
    readonlyvalue = true;
  end
  if window.getDatabaseNode() and window.getDatabaseNode().isStatic() then
    readonlyvalue = true;
  end
end

function capture()
  source = window.getDatabaseNode().createChild(sourcenodename, "number");
  if source then
    window.getDatabaseNode().onChildUpdate = function () end;
    if checked then
      source.setValue(1);
    end      
    source.onUpdate = update;
    update();
  end
end
