local Path = require('path')

local paths = {
  "/foo/bar/../baz/./42",
  "/foo/bar/../baz/./42/",
  "foo/bar/../baz/./42",
  "foo/bar/../baz/./42/",
  "/foo/../",
  "/foo/..",
  "foo/../",
  "foo/..",
  "/foo/baz/../",
  "/foo/baz/..",
  "foo/baz/../",
  "foo/baz/..",
  "/foo/baz/../hello.world",
  "/foo/baz/../this.is.cool",
  "foo/baz/../why.do.ext",
  "foo/baz/../cause.it's.cool",
}

for i, path in ipairs(paths) do
  local normal = Path.normalize(path)
  p("normalize", path, normal, Path.dirname(normal))
end



