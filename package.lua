return {
  name = "luvit/luvit",
  version = "2.13.0",
  luvi = {
    version = "2.7.6",
    flavor = "regular",
  },
  license = "Apache 2",
  homepage = "https://github.com/luvit/luvit",
  description = "node.js style APIs for luvi as either a luvi app or library.",
  tags = { "luvit", "meta" },
  author = { name = "Tim Caswell" },
  contributors = {
    "Ryan Phillips",
    "George Zhao",
    "Rob Emanuele",
    "Daniel Barney",
    "Ryan Liptak",
    "Kenneth Wilke",
    "Gabriel Nicolas Avellaneda",
  },
  dependencies = {
    "luvit/core@2.0.0",
    "luvit/hooks@2.0.0",
    "luvit/los@2.0.0",
    "luvit/pretty-print@2.0.0",
    "luvit/readline@2.0.0",
    "luvit/repl@2.0.0",
    "luvit/require@2.0.1",
    "luvit/resource@2.0.0",
    "luvit/ustring@2.0.0",
    "luvit/utils@2.0.0"
  },
  files = {
    "*.lua",
    "!examples",
    "!tests",
    "!bench",
    "!lit-*",
  }
}
