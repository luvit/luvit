-- Copyright 2015 Boundary
-- @brief convenience variables and functions for Lua scripts
-- @file boundary.lua
--
--[[lit-meta
  name = "luvit/boundary"
  version = "2.0.0"
  license = "Apache 2"
  homepage = "https://github.com/luvit/luvit/blob/master/deps/core.lua"
  description = "Core object model for luvit using simple prototypes and inheritance."
  tags = {"luvit", "objects", "inheritance"}
]]
local fs = require('fs')
local json = require('json')
local path = require('path')

local boundary = {argv = nil, param = nil, plugin = {}}
local plugin_basedir = "."

-- create table of cmdline args (boundary.argv)
boundary.argv = process.argv or nil
if boundary.argv ~= nil then
  -- if '--plguin-basedir' is present as the first arg, use its value as the path
  -- to the param.json file and remove it from the arg table
  if boundary.argv[1] == '--plugin-basedir' then
    plugin_basedir = boundary.argv[2]
    table.remove(boundary.argv, 1)
    table.remove(boundary.argv, 1)
  end
end

-- import param.json data into a Lua table (boundary.param)
local json_blob
if (pcall(function () json_blob = fs.readFileSync(plugin_basedir.."/param.json") end)) then
  pcall(function () boundary.param = json.parse(json_blob) end)
end
if (pcall(function () json_blob = fs.readFileSync("./plugin.json") end)) then
  pcall(function () boundary.plugin = json.parse(json_blob) end)
end
-- set defaults if version and name are not present
boundary.plugin.version = boundary.plugin.version or "0.0"
if boundary.plugin.name == nil then
  local cwd = process.cwd()
  boundary.plugin.name = path.basename(cwd)
  if boundary.plugin.name == "plugin" then
    boundary.plugin.name = path.basename(path.dirname(cwd))
  end
end

return boundary
