#!/usr/local/bin/lua50

--[[
-- $Id: rand.lua,v 1.1 2006/08/25 03:24:17 nezroy Exp $
-- See Copyright Notice in license.html
--]]

require "crypto"
local rand = crypto.rand

print("RAND version: " .. crypto._VERSION)
print("")

local SEEDFILE = "tmp.rnd"

if rand.load(SEEDFILE) then
	print("loaded previous random seed")
end

if rand.status() then
	print("ready to generate")
	print("")
else
	print("The PRNG does not yet have enough data.")
	local prompt = "Please type some random characters and press ENTER: "
	repeat
		io.write(prompt); io.flush()
		local line = io.read("*l")
		-- entropy of English is 1.1 bits per character
		rand.add(line, string.len(line) * 1.1 / 8)
		prompt = "More: "
	until rand.status()
end

local N = 20
local S = 5

print(string.format("generating %d sets of %d random bytes using pseudo_bytes()", S, N))
for i = 1, S do
	local data = assert(rand.pseudo_bytes(N))
	print(table.concat({string.byte(data, 1, N)}, ","))
end
print("")

print(string.format("generating %d sets of %d random bytes using bytes()", S, N))
for i = 1, S do
	local data = assert(rand.bytes(N))
	print(table.concat({string.byte(data, 1, N)}, ","))
end
print("")

print("saving seed in " .. SEEDFILE)
print("")
rand.write(SEEDFILE)

-- don't leave any sensitive data lying around in memory
print("cleaning up state")
print("")
rand.cleanup()
