--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

--- luvit thread management
local uv = require('uv')
local base = require('luvi').bundle.base

exports.name = "luvit/thread"
exports.version = "0.1.0"
exports.license = "Apache 2"
exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/thread.lua"
exports.description = "thread module for luvit"
exports.tags = {"luvit", "thread"}

exports.start = function(thread_func, ...)
  local dumped = string.dump(thread_func)

  function thread_entry(dumped, base,...)
    --- set thread luvit enviroment, mainly copy from luvi/src/init.lua
    local os = require('ffi').os
    local env = require('env')
    local uv = require('uv')
    local luvi = require('luvi')
    local miniz = require('miniz')

    local getPrefix, splitPath, joinParts

    local tmpBase = os == "Windows" and (env.get("TMP") or uv.cwd()) or
                                        (env.get("TMPDIR") or '/tmp')

    if os == "Windows" then
      -- Windows aware path utilities
      function getPrefix(path)
        return path:match("^%a:\\") or
               path:match("^/") or
               path:match("^\\+")
      end
      function splitPath(path)
        local parts = {}
        for part in string.gmatch(path, '([^/\\]+)') do
          table.insert(parts, part)
        end
        return parts
      end
      function joinParts(prefix, parts, i, j)
        if not prefix then
          return table.concat(parts, '/', i, j)
        elseif prefix ~= '/' then
          return prefix .. table.concat(parts, '\\', i, j)
        else
          return prefix .. table.concat(parts, '/', i, j)
        end
      end
    else
      -- Simple optimized versions for UNIX systems
      function getPrefix(path)
        return path:match("^/")
      end
      function splitPath(path)
        local parts = {}
        for part in string.gmatch(path, '([^/]+)') do
          table.insert(parts, part)
        end
        return parts
      end
      function joinParts(prefix, parts, i, j)
        if prefix then
          return prefix .. table.concat(parts, '/', i, j)
        end
        return table.concat(parts, '/', i, j)
      end
    end

    local function pathJoin(...)
      local inputs = {...}
      local l = #inputs

      -- Find the last segment that is an absolute path
      -- Or if all are relative, prefix will be nil
      local i = l
      local prefix
      while true do
        prefix = getPrefix(inputs[i])
        if prefix or i <= 1 then break end
        i = i - 1
      end

      -- If there was one, remove its prefix from its segment
      if prefix then
        inputs[i] = inputs[i]:sub(#prefix)
      end

      -- Split all the paths segments into one large list
      local parts = {}
      while i <= l do
        local sub = splitPath(inputs[i])
        for j = 1, #sub do
          parts[#parts + 1] = sub[j]
        end
        i = i + 1
      end

      -- Evaluate special segments in reverse order.
      local skip = 0
      local reversed = {}
      for idx = #parts, 1, -1 do
        local part = parts[idx]
        if part == '.' then
          -- Ignore
        elseif part == '..' then
          skip = skip + 1
        elseif skip > 0 then
          skip = skip - 1
        else
          reversed[#reversed + 1] = part
        end
      end

      -- Reverse the list again to get the correct order
      parts = reversed
      for idx = 1, #parts / 2 do
        local j = #parts - idx + 1
        parts[idx], parts[j] = parts[j], parts[idx]
      end

      local path = joinParts(prefix, parts)
      return path
    end

    -- Bundle from folder on disk
    local function folderBundle(base)
      local bundle = { base = base }

      function bundle.stat(path)
        path = pathJoin(base, "./" .. path)
        local raw, err = uv.fs_stat(path)
        if not raw then return nil, err end
        return {
          type = string.lower(raw.type),
          size = raw.size,
          mtime = raw.mtime,
        }
      end

      function bundle.readdir(path)
        path = pathJoin(base, "./" .. path)
        local req, err = uv.fs_scandir(path)
        if not req then
          return nil, err
        end

        local files = {}
        repeat
          local ent = uv.fs_scandir_next(req)
          if ent then
            files[#files + 1] = ent.name
          end
        until not ent
        return files
      end

      function bundle.readfile(path)
        path = pathJoin(base, "./" .. path)
        local fd, stat, data, err
        stat, err = uv.fs_stat(path)
        if not stat then return nil, err end
        if stat.type ~= "file" then return end
        fd, err = uv.fs_open(path, "r", 0644)
        if not fd then return nil, err end
        if stat then
          data, err = uv.fs_read(fd, stat.size, 0)
        end
        uv.fs_close(fd)
        return data, err
      end

      return bundle
    end

    -- Insert a prefix into all bundle calls
    local function chrootBundle(bundle, prefix)
      local bundleStat = bundle.stat
      function bundle.stat(path)
        return bundleStat(prefix .. path)
      end
      local bundleReaddir = bundle.readdir
      function bundle.readdir(path)
        return bundleReaddir(prefix .. path)
      end
      local bundleReadfile = bundle.readfile
      function bundle.readfile(path)
        return bundleReadfile(prefix .. path)
      end
    end

    -- Use a zip file as a bundle
    local function zipBundle(base, zip)
      local bundle = { base = base }

      function bundle.stat(path)
        path = pathJoin("./" .. path)
        if path == "" then
          return {
            type = "directory",
            size = 0,
            mtime = 0
          }
        end
        local err
        local index = zip:locate_file(path)
        if not index then
          index, err = zip:locate_file(path .. "/")
          if not index then return nil, err end
        end
        local raw = zip:stat(index)

        return {
          type = raw.filename:sub(-1) == "/" and "directory" or "file",
          size = raw.uncomp_size,
          mtime = raw.time,
        }
      end

      function bundle.readdir(path)
        path = pathJoin("./" .. path)
        local index, err
        if path == "" then
          index = 0
        else
          path = path .. "/"
          index, err = zip:locate_file(path )
          if not index then return nil, err end
          if not zip:is_directory(index) then
            return nil, path .. " is not a directory"
          end
        end
        local files = {}
        for i = index + 1, zip:get_num_files() do
          local filename = zip:get_filename(i)
          if string.sub(filename, 1, #path) ~= path then break end
          filename = filename:sub(#path + 1)
          local n = string.find(filename, "/")
          if n == #filename then
            filename = string.sub(filename, 1, #filename - 1)
            n = nil
          end
          if not n then
            files[#files + 1] = filename
          end
        end
        return files
      end

      function bundle.readfile(path)
        path = pathJoin("./" .. path)
        local index, err = zip:locate_file(path)
        if not index then return nil, err end
        return zip:extract(index)
      end

      -- Support zips with a single folder inserted at top-level
      local entries = bundle.readdir("")
      if #entries == 1 and bundle.stat(entries[1]).type == "directory" then
        chrootBundle(bundle, entries[1] .. '/')
      end

      return bundle
    end


    -- Given a list of bundles, merge them into a single VFS.  Lower indexed items
    -- overshadow later items.
    local function combinedBundle(bundles)
      local bases = {}
      for i = 1, #bundles do
        bases[i] = bundles[i].base
      end
      local bundle = { base = table.concat(bases, ";") }

      function bundle.stat(path)
        local err
        for i = 1, #bundles do
          local stat
          stat, err = bundles[i].stat(path)
          if stat then return stat end
        end
        return nil, err
      end

      function bundle.readdir(path)
        local has = {}
        local files, err
        for i = 1, #bundles do
          local list
          list, err = bundles[i].readdir(path)
          if list then
            for j = 1, #list do
              local name = list[j]
              if has[name] then
                print("Warning multiple overlapping versions of " .. name)
              else
                has[name] = true
                if files then
                  files[#files + 1] = name
                else
                  files = { name }
                end
              end
            end
          end
        end
        if files then
          return files
        else
          return nil, err
        end
      end

      function bundle.readfile(path)
        local err
        for i = 1, #bundles do
          local data
          data, err = bundles[i].readfile(path)
          if data then return data end
        end
        return nil, err
      end

      return bundle
    end

    local function makeBundle(bundlePaths)
      local parts = {}
      for n = 1, #bundlePaths do
        local path = pathJoin(uv.cwd(), bundlePaths[n])
        bundlePaths[n] = path
        local bundle
        local zip = miniz.new_reader(path)
        if zip then
          bundle = zipBundle(path, zip)
        else
          local stat = uv.fs_stat(path)
          if not stat or stat.type ~= "directory" then
            error("ERROR: " .. path .. " is not a zip file or a folder")
          end
          bundle = folderBundle(path)
        end
        parts[n] = bundle
      end
      if #parts == 1 then
        return parts[1]
      end
      return combinedBundle(parts)
    end

    local function commonBundle(bundle, args, bundlePaths, mainPath)

      luvi.makeBundle = makeBundle
      luvi.bundle = bundle

      mainPath = mainPath or "main.lua"

      bundle.paths = bundlePaths
      bundle.mainPath = mainPath

      luvi.path = {
        join = pathJoin,
        getPrefix = getPrefix,
        splitPath = splitPath,
        joinparts = joinParts,
      }

      function bundle.action(path, action, ...)
        -- If it's a real path, run it directly.
        if uv.fs_access(path, "r") then return action(path) end
        -- Otherwise, copy to a temporary folder and run from there
        local data, err = bundle.readfile(path)
        if not data then return nil, err end
        local dir = assert(uv.fs_mkdtemp(pathJoin(tmpBase, "lib-XXXXXX")))
        path = pathJoin(dir, path:match("[^/\\]+$"))
        local fd = uv.fs_open(path, "w", 384) -- 0600
        uv.fs_write(fd, data, 0)
        uv.fs_close(fd)
        local success, ret = pcall(action, path, ...)
        uv.fs_unlink(path)
        uv.fs_rmdir(dir)
        assert(success, ret)
        return ret
      end

      function bundle.register(name, path)
        if not path then path = name + ".lua" end
        package.preload[name] = function (...)
          local lua = assert(bundle.readfile(path))
          return assert(loadstring(lua, "bundle:" .. path))(...)
        end
      end

      _G.args = args

      -- Auto-register the require system if present
      local mainRequire
      local stat = bundle.stat("deps/require.lua")

      if stat and stat.type == "file" then
        bundle.register('require', "deps/require.lua")
        _G.require = require('require')("bundle:main.lua")
      end

      -- Auto-setup global p and libuv version of print
      if require and bundle.stat("deps/pretty-print") or bundle.stat("deps/pretty-print.lua") then
        _G.p = require('pretty-print').prettyPrint
      end
    end

    -- First check for a bundled zip file appended to the executable
    local path = uv.exepath()
    local zip = miniz.new_reader(path)
    if zip then
      commonBundle(zipBundle(path, zip), {}, {path})
    else
      -- lanched from luvit app dir
      local bundles = { base or '.' }
      local bundle = assert(makeBundle(bundles))
      -- Run the luvi app with the extra args
      commonBundle(bundle, {}, bundles)
    end

    loadstring(dumped)(...)

    uv.run()
  end

  return uv.new_thread(thread_entry,dumped,base, ...)
end

exports.join = function(thread)
    return uv.thread_join(thread)
end

exports.equals = function(thread1,thread2)
    return uv.thread_equals(thread1,thread2)
end

exports.self = function()
    return uv.thread_self()
end
