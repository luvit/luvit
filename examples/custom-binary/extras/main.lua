print("Custom main with custom builtins!")
print("1 + 2", require("add")(1, 2))
print("3 - 2", require("multi")(3, 2))
p(process.argv)

