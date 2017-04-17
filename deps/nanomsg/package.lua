return {
  name = "zhaozg/nonamsg",
  version = "0.0.1",
  homepage = "https://github.com/zhaozg/lit-nonamsg",
  description = "FFI bindings to the nanomsg library",
  tags = {"ffi", "nonamsg", "MQ"},
  author = { name = "George Zhao" },
  license = "MIT",
  files = {
    "*.lua",
    "*.h",
    "!nonamsg",
    "!nonamsg-sample",
    "$OS-$ARCH/*",
  },
  dependencies = {
    "luvit/timer@1.0.0",
    "luvit/utils@1.0.0",
    "luvit/core@1.0.2",
  }
}
