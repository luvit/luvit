return {
  name = "luvit/luvit",
  version = "2.16.0",
  luvi = {
    version = "2.10.1",
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
    "luvit/buffer@2.0.0",
    "luvit/childprocess@2.1.2",
    "luvit/codec@2.0.0",
    "luvit/core@2.0.2",
    "luvit/dgram@2.0.0",
    "luvit/dns@2.0.3",
    "luvit/fs@2.0.1",
    "luvit/helpful@2.0.1",
    "luvit/hooks@2.0.0",
    "luvit/http@2.1.4",
    "luvit/http-codec@2.0.3",
    "luvit/http-header@1.0.0",
    "luvit/https@2.0.0",
    "luvit/json@2.5.1",
    "luvit/los@2.0.0",
    "luvit/net@2.0.3",
    "luvit/path@2.0.1",
    "luvit/pretty-print@2.0.1",
    "luvit/process@2.1.1",
    "luvit/querystring@2.0.1",
    "luvit/readline@2.0.0",
    "luvit/repl@2.1.2",
    "luvit/require@2.2.2",
    "luvit/resource@2.0.0",
    "luvit/stream@2.0.1",
    "luvit/thread@2.0.0",
    "luvit/timer@2.0.1",
    "luvit/tls@2.3.0",
    "luvit/utils@2.0.0",
    "luvit/url@2.1.2",
    "luvit/ustring@2.0.0"
  },
  files = {
    "*.lua",
    "!examples",
    "!tests",
    "!bench",
    "!lit-*",
  }
}
