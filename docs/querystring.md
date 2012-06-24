# Query String

Helper for parsing, encoding and decoding query strings

## querystring.parse(str, [sep], [eq])

Parses a querystring, returning table of url decoded tokens.

Optionally override the default separator ('&') and assignment ('=') characters.

### Examples

```lua
local qs = require("querystring")

local to_parse = "name=luvit&version=0.4.0"
local parsed = qs.parse(to_parse)
for i,v in pairs(parsed) do print(i,v) end

--[[
Output
    name	luvit
    version	0.4.0
]]--
```

```lua
local qs = require("querystring")

local to_parse = "name==luvit||version==0.4.0"
local parsed = qs.parse(to_parse, "||", "==")
for i,v in pairs(parsed) do print(i,v) end

--[[
Output
    name	luvit
    version	0.4.0
]]--
```

## querystring.urlencode(str)

Encodes a string to be used in the query part of a url. Spaces are encoded to plus (+) signs. Non alpha-numeric characters are encoded to their hexadecimal equivalent.

### Example
```lua
local qs = require("querystring")

local example = "this is a £test <to encode>"
local encoded = qs.urlencode(example)

print ("Encoded: ",encoded)

--[[
Output
    Encoded: 	this+is+a+%C2%A3test+%3Cto+encode%3E
]]--
```

## querystring.urldecode(str)

Decodes a urlencoded string.

### Example
```lua
local qs = require("querystring")

local example = "this+is+a+%C2%A3test+%3Cto+encode%3E"
local decoded = qs.urldecode(encoded)

print ("Decoded: ",decoded)

--[[
Output
    Decoded: 	this is a £test <to encode>
]]--
```
