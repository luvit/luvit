var defs = {};
var modules = {};
function define(name, fn) {
  defs[name] = fn;
}
function require(name) {
  if (modules.hasOwnProperty(name)) return modules[name];
  if (defs.hasOwnProperty(name)) {
    var fn = defs[name];
    defs[name] = function () { throw new Error("Circular Dependency"); };
    return modules[name] = fn();
  }
  throw new Error("Module not found: " + name);
}
