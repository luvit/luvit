local exports = {}
print("Load parent module")
exports.name = "Parent"
exports.child = require('./child')
print("Loaded parent module")

print(...)

return exports

