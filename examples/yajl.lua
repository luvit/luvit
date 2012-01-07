local Yajl = require('yajl')

local parser = Yajl.new({
  allow_comments = true,
  on_null = function ()
    p("on_null")
  end,
  on_boolean = function (value)
    p("on_boolean", value)
  end,
  on_number = function (value)
    p("on_number", value)
  end,
  on_string = function (value)
    p("on_string", value)
  end,
  on_start_map = function ()
    p("on_start_map")
  end,
  on_map_key = function (key)
    p("on_map_key", key)
  end,
  on_end_map = function ()
    p("on_end_map")
  end,
  on_start_array = function ()
    p("on_start_array")
  end,
  on_end_array = function ()
    p("on_end_array")
  end
})

p(parser)

parser:parse([[
{
  //hello?
  "name":"tim",
  "stuff": [null, true, false, 0, 0.1, -0.11, "foo", {}],
  "values":
]])
parser:parse("[1,2,3]")
parser:parse("}")
