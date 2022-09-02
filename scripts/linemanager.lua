-- This file is provided under the Open Game License version 1.0a
-- For more information on OGL and related issues, see 
--   http://www.wizards.com/d20

-- All producers of work derived from this definition are adviced to
-- familiarize themselves with the above license, and to take special
-- care in providing the definition of Product Identity (as specified
-- by the OGL) in their products.

-- Copyright 2009 SmiteWorks Ltd.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- The LineManager module allows gamelines to be added dynamically to the ruleset, enabling extensions to provide
-- support for different products (such as Vampire:The Requiem).
--
-- The ruleset is distributed with a default line (Mortal), which is defined below.
--

local linelist = {};
local default = nil;

lineCount = 0;

-- ##################### External Functions - can be called by other code #########################################

function register(gameline, isdefault)
  local name;
  if gameline then
    name = gameline.Name;
	print("extension "..name.." Loaded");
  else
    return false;
  end
  if type(name)~="string" or name=="" then
    return false;
  end
  if not linelist[name] then
    lineCount = lineCount + 1;
  end
  linelist[name] = gameline;
  if isdefault then
    default = name;
  end
  return true;  
end

function getLine(name)
  if name and linelist[name] then
    return linelist[name];
  end
  if default and linelist[default] then
    return linelist[default];
  end
  return nil;
end

function getLines()
  return linelist;
end

function getDefaultName()
  return default;
end
