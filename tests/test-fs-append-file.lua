--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License")
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

require("helper")

local FS = require('fs')
local join = require('path').join
local Buffer = require('buffer').Buffer

local filename = join(__dirname, 'fixtures', 'append.txt')

p('appending to ' .. filename)

local currentFileData = 'ABCD'

local n = 220
local s = '南越国是前203年至前111年存在于岭南地区的一个国家，国都位于番禺，疆域包括今天中国的广东、' ..
        '广西两省区的大部份地区，福建省、湖南、贵州、云南的一小部份地区和越南的北部。' ..
        '南越国是秦朝灭亡后，由南海郡尉赵佗于前203年起兵兼并桂林郡和象郡后建立。' ..
        '前196年和前179年，南越国曾先后两次名义上臣属于西汉，成为西汉的“外臣”。前112年，' ..
        '南越国末代君主赵建德与西汉发生战争，被汉武帝于前111年所灭。南越国共存在93年，' ..
        '历经五代君主。南越国是岭南地区的第一个有记载的政权国家，采用封建制和郡县制并存的制度，' ..
        '它的建立保证了秦末乱世岭南地区社会秩序的稳定，有效的改善了岭南地区落后的政治、##济现状。\n'

local ncallbacks = 0

-- test that empty file will be created and have content added
FS.appendFile(filename, s, function(e)
  if e then
    return e
  end

  ncallbacks = ncallbacks + 1
  p('appended to file')

  FS.readFile(filename, function(e, buffer)
    if e then
      return e
    end
    p('file read')
    ncallbacks = ncallbacks + 1
    assert(#buffer == #s)
  end)
end)

-- test that appends data to a non empty file
local filename2 = join(__dirname, 'fixtures', 'append2.txt')
FS.writeFileSync(filename2, currentFileData)

FS.appendFile(filename2, s, function(e)
  if e then
    return e
  end

  ncallbacks = ncallbacks + 1
  p('appended to file2')

  FS.readFile(filename2, function(e, buffer)
    if e then
      return e
    end
    p('file2 read')
    ncallbacks = ncallbacks + 1
    assert(#buffer == #s + #currentFileData)
  end)
end)

-- test that appendFile accepts buffers
local filename3 = join(__dirname, 'fixtures', 'append3.txt')
FS.writeFileSync(filename3, currentFileData)

local buf = Buffer:new(s)
p('appending to ' .. filename3)

FS.appendFile(filename3, buf:toString(), function(e)
  if e then
    return e
  end

  ncallbacks = ncallbacks + 1
  p('appended to file3')

  FS.readFile(filename3, function(e, buffer)
    if e then
      return e
    end
    p('file3 read')
    ncallbacks = ncallbacks + 1
    assert(#buffer == buf.length + #currentFileData)
  end)
end)

-- test that appendFile accepts numbers.
local filename4 = join(__dirname, 'fixtures', 'append4.txt')
FS.writeFileSync(filename4, currentFileData)

p('appending to ' .. filename4)

FS.appendFile(filename4, tostring(n), function(e)
  if e then
    return e
  end

  ncallbacks = ncallbacks + 1
  p('appended to file4')

  FS.readFile(filename4, function(e, buffer)
    if e then
      return e
    end
    p('file4 read')
    ncallbacks = ncallbacks + 1
    assert(#buffer == #tostring(n) + #currentFileData)
  end)
end)

process:on('exit', function()
  p('done')
  assert(ncallbacks == 8)

  FS.unlinkSync(filename)
  FS.unlinkSync(filename2)
  FS.unlinkSync(filename3)
  FS.unlinkSync(filename4)
end)
