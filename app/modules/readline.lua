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
exports.name = "creationix/readline"
exports.version = "1.0.1"

-- Heavily inspired by ljlinenoise : <http://fperrad.github.io/ljlinenoise/>

local sub = string.sub
local gmatch = string.gmatch
local remove = table.remove
local insert = table.insert
local concat = table.concat

local History = {}
exports.History = History
function History:add(line)
  assert(type(line) == "string", "line must be string")
  while #self >= self.maxLength do
    remove(self, 1)
  end
  insert(self, line)
  return true
end
function History:setMaxLength(length)
  assert(type(length) == "number", "max length length must be number")
  self.maxLength = length
  while #self > length do
    remove(self, 1)
  end
  return true
end
function History:clean()
  for i = 1, #self do
    self[i] = nil
  end
  return true
end
function History:dump()
  return concat(self, "\n") .. '\n'
end
function History:load(data)
  assert(type(data) == "string", "history dump required as string")
  for line in gmatch(data, "[^\n]+") do
    insert(self, line)
  end
  return true
end
function History:updateLastLine(line)
  self[#self] = line
end
History.__index = History
function History.new()
  local history = { maxLength = 100 }
  return setmetatable(history, History)
end

local Editor = {}
exports.Editor = Editor
function Editor:refreshLine()
  local line = self.line
  local position = self.position

  -- Cursor to left edge
  local command = "\x1b[0G"
  -- Write the prompt and the current buffer content
               .. self.prompt .. line
  -- Erase to right
               .. "\x1b[0K"
  -- Move cursor to original position.
               .. "\x1b[0G\x1b[" .. tostring(position + self.promptLength - 1) .. "C"
  self.stdout:write(command)
end
function Editor:insert(character)
  local line = self.line
  local position = self.position
  if #line == position - 1 then
    self.line = line .. character
    self.position = position + 1
    if self.promptLength + #self.line < self.columns then
      self.stdout:write(character)
    else
      self:refreshLine()
    end
  else
    -- Insert the letter in the middle of the line
    self.line = sub(line, 1, position - 1) .. character .. sub(line, position)
    self.position = position + 1
    self:refreshLine()
  end
  self.history:updateLastLine(self.line)
end
function Editor:moveLeft()
  if self.position > 1 then
    self.position = self.position - 1
    self:refreshLine()
  end
end
function Editor:moveRight()
  if self.position - 1 ~= #self.line then
    self.position = self.position + 1
    self:refreshLine()
  end
end
function Editor:getHistory(delta)
  local history = self.history
  local length = #history
  local index = self.historyIndex
  if length > 1 then
    index = index + delta
    if index < 1 then
      index = 1
    elseif index > length then
      index = length
    end
    if index == self.historyIndex then return end
    local line = self.history[index]
    self.line = line
    self.historyIndex = index
    self.position = #line + 1
    self:refreshLine()
  end
end
function Editor:backspace()
  local line = self.line
  local position = self.position
  if position > 1 and #line > 0 then
    self.line = sub(line, 1, position - 2) .. sub(line, position)
    self.position = position - 1
    self.history:updateLastLine(self.line)
    self:refreshLine()
  end
end
function Editor:delete()
  local line = self.line
  local position = self.position
  if position > 0 and #line > 0 then
    self.line = sub(line, 1, position - 1) .. sub(line, position + 1)
    self.history:updateLastLine(self.line)
    self:refreshLine()
  end
end
function Editor:swap()
  local line = self.line
  local position = self.position
  if position > 1 and position <= #line then
    self.line = sub(line, 1, position - 2)
             .. sub(line, position, position)
             .. sub(line, position - 1, position - 1)
             .. sub(line, position + 1)
    if position ~= #line then
      self.position = position + 1
    end
    self.history:updateLastLine(self.line)
    self:refreshLine()
  end
end
function Editor:deleteLine()
  self.line = ''
  self.position = 1
  self.history:updateLastLine(self.line)
  self:refreshLine()
end
function Editor:deleteEnd()
  self.line = sub(self.line, 1, self.position - 1)
  self.history:updateLastLine(self.line)
  self:refreshLine()
end
function Editor:moveHome()
  self.position = 1
  self:refreshLine()
end

function Editor:moveEnd()
  self.position = #self.line + 1
  self:refreshLine()
end
local function findLeft(line, position, wordPattern)
  local pattern = wordPattern .. "$"
  if position == 1 then return 1 end
  local s
  repeat
    local start = sub(line, 1, position - 1)
    s = string.find(start, pattern)
    if not s then
      position = position - 1
    end
  until s or position == 1
  return s or position
end

function Editor:deleteWord()
  local position = self.position
  local line = self.line
  self.position = findLeft(line, position, self.wordPattern)
  self.line = sub(line, 1, self.position - 1) .. sub(line, position)
  self:refreshLine()
end

function Editor:jumpLeft()
  self.position = findLeft(self.line, self.position, self.wordPattern)
  self:refreshLine()
end
function Editor:jumpRight()
  local _, e = string.find(self.line, self.wordPattern, self.position)
  self.position = e and e + 1 or #self.line + 1
  self:refreshLine()
end
function Editor:clearScreen()
  self.stdout:write('\x1b[H\x1b[2J')
  self:refreshLine()
end
function Editor:beep()
  self.stdout:write('\x07')
end
function Editor:complete()
  if not self.completionCallback then
    return self:beep()
  end
  local line = self.line
  local position = self.position
  local res = self.completionCallback(sub(line, 1, position))
  if not res then
    return self:beep()
  end
  local typ = type(res)
  if typ == "string" then
    self.line = res .. sub(line, position + 1)
    self.position = #res + 1
    self.history:updateLastLine(self.line)
  elseif typ == "table" then
    print()
    print(unpack(res))
  end
  self:refreshLine()
end

function Editor:onKey(key)
  local char = string.byte(key, 1)
  if     char == 13 then  -- Enter
    local history = self.history
    local line = self.line
    -- Only record new history if it's non-empty and new
    if #line > 0 and history[#history - 1] ~= line then
      history[#history] = line
    else
      history[#history] = nil
    end
    return self.line
  elseif char == 9 then   -- Tab
    self:complete()
  elseif char == 3 then   -- Control-C
    self.stdout:write("^C\n")
    if #self.line > 0 then
      self:deleteLine()
    else
      return false, "SIGINT in readLine"
    end
  elseif char == 127      -- Backspace
      or char == 8 then   -- Control-H
    self:backspace()
  elseif char == 4 then   -- Control-D
    if #self.line > 0 then
      self:delete()
    else
      self.history:updateLastLine()
      return nil, "EOF in readLine"
    end
  elseif char == 20 then  -- Control-T
    self:swap()
  elseif key == '\027[A'  -- Up Arrow
      or char == 16 then  -- Control-P
    self:getHistory(-1)
  elseif key == '\027[B'  -- Down Arrow
      or char == 14 then  -- Control-N
    self:getHistory(1)
  elseif key == '\027[C'  -- Right Arrow
      or char == 6 then   -- Control-F
    self:moveRight()
  elseif key == '\027[D'  -- Left Arrow
      or char == 2 then   -- Control-B
    self:moveLeft()
  elseif key == '\027[H'  -- Home Key
      or key == '\027OH'  -- Home for terminator
      or key == '\027[1~' -- Home for CMD.EXE
      or char == 1 then   -- Control-A
    self:moveHome()
  elseif key == '\027[F'  -- End Key
      or key == '\027OF'  -- End for terminator
      or key == '\027[4~' -- End for CMD.EXE
      or char == 5 then   -- Control-E
    self:moveEnd()
  elseif char == 21 then  -- Control-U
    self:deleteLine()
  elseif char == 11 then  -- Control-K
    self:deleteEnd()
  elseif char == 12 then  -- Control-L
    self:clearScreen()
  elseif char == 23 then  -- Control-W
    self:deleteWord()
  elseif key == '\027[3~' then -- Delete Key
    self:delete()
  elseif key == '\027[1;5D'  -- Control Left Arrow
      or key == '\027\027[D' -- Alt Left Arrow (iTerm.app)
      or key == '\027b' then -- Alt Left Arrow (Terminal.app)
    self:jumpLeft()
  elseif key == '\027[1;5C'  -- Control Right Arrow
      or key == '\027\027[C' -- Alt Right Arrow (iTerm.app)
      or key == '\027f' then -- Alt Right Arrow (Terminal.app)
    self:jumpRight()
  elseif key == '\027\027[A'   -- Alt Up Arrow (iTerm.app)
      or key == '\027[5~' then -- Page Up
    self:getHistory(-10)
  elseif key == '\027\027[B'   -- Alt Down Arrow (iTerm.app)
      or key == '\027[6~' then -- Page Down
    self:getHistory(10)
  elseif char > 31 then
    self:insert(key)
  else
    p(char, key)
  end
  return true
end
function Editor:readLine(prompt, callback)

  local onKey, finish

  self.prompt = prompt
  self.promptLength = #prompt
  self.columns = self.stdout:get_winsize() or 80

  function onKey(err, key)
    local r, out, reason = pcall(function ()
      assert(not err, err)
      return self:onKey(key)
    end)
    if r then
      if out == true then return end
      return finish(nil, out, reason)
    else
      return finish(out)
    end
  end

  function finish(...)
    self.stdin:read_stop()
    self.stdin:set_mode(0)
    self.stdout:write('\n')
    return callback(...)
  end

  self.line = ""
  self.position = 1
  self.stdout:write(self.prompt)
  self.history:add(self.line)
  self.historyIndex = #self.history,

  self.stdin:set_mode(1)
  self.stdin:read_start(onKey)

end
Editor.__index = Editor
function Editor.new(options)
  options = options or {}
  local history = options.history or History.new()
  assert(options.stdin, "stdin is required")
  assert(options.stdout, "stdout is required")
  local editor = {
    wordPattern = options.wordPattern or "%w+",
    history = history,
    completionCallback = options.completionCallback,
    stdin = options.stdin,
    stdout = options.stdout,
  }
  return setmetatable(editor, Editor)
end

exports.readLine = function (prompt, options, callback)
  if type(options) == "function" and callback == nil then
    callback, options = options, callback
  end
  local editor = Editor.new(options)
  editor:readLine(prompt, callback)
  return editor
end
