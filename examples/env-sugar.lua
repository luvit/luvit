

p(env)
p("HOME", env.HOME)
p("BAD", env.BAD)
env.BAD = 42
p("BAD", env.BAD)
env.BAD = nil
p("BAD", env.BAD)


