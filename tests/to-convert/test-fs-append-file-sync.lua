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

local currentFileData = 'ABCD'

local num = 220
local data = '南越国是前203年至前111年存在于岭南地区的一个国家，国都位于番禺，疆域包括今天中国的广东、' ..
        '广西两省区的大部份地区，福建省、湖南、贵州、云南的一小部份地区和越南的北部。' ..
        '南越国是秦朝灭亡后，由南海郡尉赵佗于前203年起兵兼并桂林郡和象郡后建立。' ..
        '前196年和前179年，南越国曾先后两次名义上臣属于西汉，成为西汉的“外臣”。前112年，' ..
        '南越国末代君主赵建德与西汉发生战争，被汉武帝于前111年所灭。南越国共存在93年，' ..
        '历经五代君主。南越国是岭南地区的第一个有记载的政权国家，采用封建制和郡县制并存的制度，' ..
        '它的建立保证了秦末乱世岭南地区社会秩序的稳定，有效的改善了岭南地区落后的政治、##济现状。\n'

-- test that empty file will be created and have content added
local filename = join(__dirname, 'fixtures', 'append-sync.txt')
p('appending to ' .. filename)
FS.appendFileSync(filename, data)

local fileData = FS.readFileSync(filename)

assert(fileData == data)

-- test that appends data to a non empty file
local filename2 = join(__dirname, 'fixtures', 'append-sync2.txt')
FS.writeFileSync(filename2, currentFileData)

-- local currentFileData2 = FS.readFileSync(filename2)
-- p('currentFileData2 == ' .. currentFileData2)
-- assert(currentFileData2 == currentFileData)

p('appending to ' .. filename2)
FS.appendFileSync(filename2, data)

local fileData2 = FS.readFileSync(filename2)

-- TODO: fix assertion error here on OSX.
assert(#fileData2 == #currentFileData + #data)

-- test that appendFileSync accepts buffers
local filename3 = join(__dirname, 'fixtures', 'append-sync3.txt')
FS.writeFileSync(filename3, currentFileData)

p('appending to ' .. filename3)

local buf = Buffer:new(data)
FS.appendFileSync(filename3, buf)

local fileData3 = FS.readFileSync(filename3)

assert(#fileData3 == buf.length + #currentFileData)

-- test that appendFile accepts numbers.
local filename4 = join(__dirname, 'fixtures', 'append-sync4.txt')
FS.writeFileSync(filename4, currentFileData)

p('appending to ' .. filename4)
FS.appendFileSync(filename4, num)

local fileData4 = FS.readFileSync(filename4)

assert(#fileData4 == #tostring(num) + #currentFileData)

--exit logic for cleanup

process:on('exit', function()
  p('done')

  FS.unlinkSync(filename)
  FS.unlinkSync(filename2)
  FS.unlinkSync(filename3)
  FS.unlinkSync(filename4)
end)
