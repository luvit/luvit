local JSON = require('json')

local value = JSON.parse([[
{
  "author": "Tim Caswell <tim@creationix.com>",
  "name": "kernel",
  "description": "A simple async template language similair to dustjs and mustache",
  "version": "0.0.3",
  "repository": {
    "url": ""
  },
  "null":[null,null,null,null],
  "main": "kernel.js",
  "engines": {
    "node": "~0.6"
  },
  "dependencies": {},
  "devDependencies": {}
}
]], true)
p(value)