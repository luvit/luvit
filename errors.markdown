
# Classes of errors

 - Sync argument errors.  These should "throw" and many do because that's how `luaL_check*` works.
 - Errors while async.  These happened while trying to do an async action.  They should either be handed to the callback or emitted as error.
 - Error while executing async callbacks.  If an error handler has a bug, there isn't much we can do.  Either "throw" or send as "error" event if possible.

# Error handling

  - async errors are always handed to lua somewhere with the exception of "error" events that aren't listened for
  - uncaught "error" events and sync errors will crash the process and should always show a stack trace

# Current places where async errors happen

I know errno and path, this is a fs error

    luv_io_error(L, req->errorno, NULL, NULL, req->path);

I only know it was the last error (`after shutdown`, `after_write`, `on_connection`)

    luv_io_error(L, uv_last_error(uv_default_loop()).code, NULL, NULL, NULL);

