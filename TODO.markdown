# Functions to Implement

This is a listing of the public API of libuv.  It's here to organize the
bindings into logical submodules and mark the implementation progress.

## Handle

 - `uv_close`: close a request handle. This MUST be called on each handle before
    memory is released.
 - `luv_set_handler`: sets the event handler for a named event on the
    environment of this userdata

## UDP

 - `uv_udp_init`: initialize an udp struct
 - `uv_udp_bind`: Bind to a IPv4 address and port.
 - `uv_udp_bind6`: Bind to a IPv6 address and port.
 - `uv_udp_getsockname`: ?
 - `uv_udp_send`: Send data
 - `uv_udp_send6`: send data
 - `uv_udp_recv_start`: start getting data
 - `uv_udp_recv_stop`: Stop listening for incoming datagrams.

## Stream

 - `uv_shutdown`: Shutdown the outgoing (write) side of a duplex stream.
 - `uv_listen`: listen?
 - `uv_accept`: accept a connection after the callback has been called
 - `uv_read_start`: start reading data from an incoming stream
 - `uv_read_stop`: stop the stream?
 - `uv_write`: write data to a stream, handles ordering for you

## TCP

 - `uv_tcp_init`: initialize a tcp struct
 - `uv_tcp_bind`: bind to an IPv4 port
 - `uv_tcp_bind6`: bind to an IPv6 port
 - `uv_tcp_getsockname`: ?
 - `uv_tcp_getpeername`: ?
 - `uv_tcp_connect`: make an IPv4 connection
 - `uv_tcp_connect6`: make an IPv6 connection

## Pipe

 - `uv_pipe_init`: initialize a pipe struct
 - `uv_pipe_open`: Opens an existing file descriptor or HANDLE as a pipe.
 - `uv_pipe_bind`: ?
 - `uv_pipe_connect`: ?

## TTY

 - `uv_tty_init`: initialize a tty struct
 - `uv_tty_set_mode`: Set mode. 0 for normal, 1 for raw.
 - `uv_tty_get_winsize`: Gets the current Window size.

## FS

 - `uv_fs_req_cleanup`: cleanup an async fs request
 - `uv_fs_close`: close an FD
 - `uv_fs_open`: open a file
 - `uv_fs_read`: read a chunk from a file
 - `uv_fs_unlink`: unlink (delete) a file
 - `uv_fs_write`: write a chunk to a file
 - `uv_fs_mkdir`: make a directory
 - `uv_fs_rmdir`: remove a directory
 - `uv_fs_readdir`: read a directory
 - `uv_fs_stat`: stat a file
 - `uv_fs_fstat`: ?
 - `uv_fs_rename`: rename a file
 - `uv_fs_fsync`: fsync a file
 - `uv_fs_fdatasync`: ?
 - `uv_fs_ftruncate`: truncate a file
 - `uv_fs_sendfile`: use kernel level sendfile?
 - `uv_fs_chmod`: change permissions
 - `uv_fs_utime`:
 - `uv_fs_futime`:
 - `uv_fs_lstat`:
 - `uv_fs_link`:
 - `uv_fs_symlink`: ?
 - `uv_fs_readlink`:
 - `uv_fs_fchmod`:
 - `uv_fs_chown`:
 - `uv_fs_fchown`:
 - `uv_fs_event_init`: watch a file or directory for changes

## SubProcess

 - `uv_spawn`: Initializes uv_process_t and starts the process
 - `uv_process_kill`: Kills the process with the specified signal

## Timers

 - `uv_timer_init`: initialize a timer struct
 - `uv_timer_start`: start a timer
 - `uv_timer_stop`: stop the timer
 - `uv_timer_again`: Stop the timer, and if it is repeating restart it using the
    repeat value as the timeout
 - `uv_timer_set_repeat`: Set the repeat value

## Timestamp Functions ?

 - `uv_update_time`: ?
 - `uv_now`: get current timestamp

## DNS

 - `uv_ares_init_options`: c-ares integration initialize and terminate
 - `uv_ares_destroy`: destroy c-ares integration
 - `uv_getaddrinfo`: Asynchronous getaddrinfo(3).
 - `uv_freeaddrinfo`: cleanup

## Event Loop functions

 - `uv_loop_new`: creates a new uv_loop_t
 - `uv_loop_delete`: deletes a uv_loop_t
 - `uv_default_loop`: returns the default loop
 - `uv_run`: starts a loop and blocks till it's done
 - `uv_ref`, `uv_unref`: Manually modify the event loop's reference count.
    Useful if the user wants to have a handle or timeout that doesn't keep the
    loop alive.
 - `uv_prepare_init`, `uv_prepare_start`, `uv_prepare_stop`: Every active
    prepare handle gets its callback called exactly once per loop iteration,
    just before the system blocks to wait for completed i/o.
 - `uv_check_init`, `uv_check_start`, `uv_check_stop`: Every active check handle
    gets its callback called exactly once per loop iteration, just after the
    system returns from blocking.
 - `uv_idle_init`, `uv_idle_start`, `uv_idle_stop`:  Every active idle handle
    gets its callback called repeatedly until it is stopped. This happens after
    all other types of callbacks are processed.  When there are multiple "idle"
    handles active, their callbacks are called in turn.
 - `uv_is_active`: Returns 1 if the prepare/check/idle handle has been started,
    0 otherwise. For other handle types this always returns 1.
 - `uv_async_init`: wake up the event loop and call the async handle's callback
 - `uv_async_send`: This can be called to wake up a libuvthread

## Misc and Utility

 - `uv_last_error`: Gets the last error on a loop
 - `uv_strerror`: gets the message for an error
 - `uv_err_name`: gets the name for an error
 - `uv_buf_init`: construct a buf
 - `uv_guess_handle`: Used to detect what type of stream should be used with a
    given file descriptor.  For isatty() functionality use this function and
    test for UV_TTY.
 - `uv_std_handle`: ??
 - `uv_queue_work`: generic work queue hook
 - `uv_exepath`: find the path of the executable
 - `uv_ip4_addr`: Convert string ip addresses to binary structures
 - `uv_ip6_addr`: Convert string ip addresses to binary structures
 - `uv_ip4_name`: Convert binary addresses to strings
 - `uv_ip6_name`: Convert binary addresses to strings

--------------------------------------------------------------------------------

# Userdata Types

Indentation denotes inheritance

- `luv_handle`: Generic handle
  - `luv_udp`: a plain udp handle
  - `luv_stream`: a fifo stream of data
    - `luv_tcp`: a tcp network connection
    - `luv_pipe`: a named socket or domain socket
    - `luv_tty`: the terminal as a stream/socket

