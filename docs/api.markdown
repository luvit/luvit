# Luvit API Docs

This is an overview of of the basic public interface to Luvit.

# Modules

These are the various modules you can require and use from your Luvit program.

## Emitter

Emitter is an event emitter for loosely coupled pub-sub style programming.  It's the root of most types in Luvit.

### `Emitter.new()`

Create a new emitter table and returns it

### `Emitter.prototype`

This table is the prototype that holds emitter instance methods.

### `Emitter.meta`

This meta-table is can be used for any table that wants to inherit from `Emitter.prototype`.

### `emitter:on(name, callback)`

Attach an event listener to the emitter instance.  Name can be any value and callback is a function that gets called when the named event gets emitted.

### `emitter:once(name, callback)`

This is just like `emitter:on(...)` except it automatically removes itself after the first time it's fired.  Thus is happens once.

### `emitter:emit(name, ...)`

Emit an event named by `name` to all the listeners.  The extra args `...` get passed as arguments to the attached listeners.

### `emitter:remove_listener(name, callback)`

Remove a single listener from the emitter.  The arguments `name` and `callback` need to be the same ones used when setting up the listener.

### `emitter:missing_handler_type(name, ...)`

This is a hook for emitters that want to be notified when an event is emitted but there is no listener for it.  By default the behavior is to check if `name` is `error` and throw the error.

### `emitter:add_handler_type(name)`

This is another hook for emitters that want to be notified the first time a handler is added for a specific `name`.  This is used internally for emitters that are backed by real OS level sources and need to register low-level listeners on the first listener they get.

## Fiber

Fiber is a tiny module that makes working with coroutines a little easier.

### Fiber.new(fn)

Create a new coroutine `fn` and then call it with two functions `resume` and `wait`.  From within this coroutine and using these two functions, you can write blocking-style code for when that's more convenient.

This does use a real Lua coroutine and as such be aware that the calls are not actually blocking.  When you call `wait` your current stack is suspended, but the event loop can execute other stacks and possible change state of variables within also used by the coroutine.

## Fs

## Http

### Request

### Response

### Stack

### Url

## Mime

## Path

## Pipe

## Process

## Stream

## Tcp

## Timer

## Tty

## Udp


