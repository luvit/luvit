exports.name = "luvit/modbus"
exports.version = "1.0.0-0"
exports.dependencies = {
}
exports.license = "Apache 2"
exports.homepage = "https://github.com/zhaozg/luvit/blob/master/deps/modbus"
exports.description = "modbus module for luvit."
exports.tags = {"luvit", "modbus"}

exports.modbus = require('./modbus')
exports.apdu = require('./apdu')
