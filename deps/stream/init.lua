--[[

Copyright 2014-2015 The Luvit Authors. All Rights Reserved.

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

exports.name = "luvit/stream"
exports.version = "1.1.0-3"
exports.dependencies = {
  "luvit/core@1.0.4",
  "luvit/utils@1.0.0",
}
exports.license = "Apache 2"
exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/stream"
exports.description = "A port of node.js's stream module for luvit."
exports.tags = {"luvit", "stream"}

exports.Stream = require('./stream_core').Stream
exports.Writable = require('./stream_writable').Writable
exports.Transform = require('./stream_transform').Transform
exports.Readable = require('./stream_readable').Readable
exports.PassThrough = require('./stream_passthrough').PassThrough
exports.Observable = require('./stream_observable').Observable
exports.Duplex = require('./stream_duplex').Duplex
