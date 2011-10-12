# Functions to Implement

This is a listing of the public API of libuv.  It's here to organize the
bindings into logical submodules and mark the implementation progress.

## Handle

 * `uv_close`: close a request handle. This MUST be called on each handle before
    memory is released.
 * `luv_set_handler`: sets the event handler for a named event on the
    environment of this userdata

## UDP

 - `luv_new_udp`: Create a new udp instance
 - `uv_udp_bind`: Bind to a IPv4 address and port.
 - `uv_udp_bind6`: Bind to a IPv6 address and port.
 - `uv_udp_getsockname`: ?
 - `uv_udp_send`: Send data
 - `uv_udp_send6`: send data
 - `uv_udp_recv_start`: start getting data
 - `uv_udp_recv_stop`: Stop listening for incoming datagrams.

## FS Watcher

 * `luv_new_fs_watcher`: create a new file watcher

## Stream

 * `uv_shutdown`: Shutdown the outgoing (write) side of a duplex stream.
 * `uv_listen`: listen?
 * `uv_accept`: accept a connection after the callback has been called
 * `uv_read_start`: start reading data from an incoming stream
 * `uv_read_stop`: stop the stream?
 - `uv_read2_start`: extended read that can pass file descriptors
 * `uv_write`: write data to a stream, handles ordering for you
 - `uv_write2`: extended write that can pass file descriptors

## TCP

 * `luv_new_tcp`: Create a new tcp instance
 * `uv_tcp_bind`: bind to an IPv4 port
 * `uv_tcp_bind6`: bind to an IPv6 port
 * `uv_tcp_getsockname`: get info about own end of socket
 * `uv_tcp_getpeername`: get info about remote end
 * `uv_tcp_connect`: make an IPv4 connection
 * `uv_tcp_connect6`: make an IPv6 connection

## Pipe

 * `luv_new_pipe`: Create a new pipe instance
 * `uv_pipe_open`: Opens an existing file descriptor or HANDLE as a pipe.
 * `uv_pipe_bind`: ?
 * `uv_pipe_connect`: ?

## TTY

 * `luv_new_tty`: Create a new tty instance
 * `uv_tty_set_mode`: Set mode. 0 for normal, 1 for raw.
 * `uv_tty_reset_mode`:
 * `uv_tty_get_winsize`: Gets the current Window size.

## FS

 * `uv_fs_close`: close an FD
 * `uv_fs_open`: open a file
 * `uv_fs_read`: read a chunk from a file
 * `uv_fs_unlink`: unlink (delete) a file
 * `uv_fs_write`: write a chunk to a file
 * `uv_fs_mkdir`: make a directory
 * `uv_fs_rmdir`: remove a directory
 * `uv_fs_readdir`: read a directory
 * `uv_fs_stat`: stat a file
 * `uv_fs_fstat`: ?
 * `uv_fs_rename`: rename a file
 * `uv_fs_fsync`: fsync a file
 * `uv_fs_fdatasync`: ?
 * `uv_fs_ftruncate`: truncate a file
 * `uv_fs_sendfile`: use kernel level sendfile?
 * `uv_fs_chmod`: change permissions
 * `uv_fs_utime`:
 * `uv_fs_futime`:
 * `uv_fs_lstat`:
 * `uv_fs_link`:
 * `uv_fs_symlink`: ?
 * `uv_fs_readlink`:
 * `uv_fs_fchmod`:
 * `uv_fs_chown`:
 * `uv_fs_fchown`:

## SubProcess

 * `uv_spawn`: Initializes uv_process_t and starts the process
 * `uv_process_kill`: Kills the process with the specified signal

## Timers

 * `luv_new_timer`:
 * `uv_timer_start`: start a timer
 * `uv_timer_stop`: stop the timer
 * `uv_timer_again`: Stop the timer, and if it is repeating restart it using the
    repeat value as the timeout
 * `uv_timer_set_repeat`: Set the repeat value
 * `uv_timer_get_repeat`: get the repeat value

## Timestamp Functions ?

 * `uv_update_time`: ?
 * `uv_now`: get current timestamp
 * `uv_hrtime`: timestamp with nanosecond precision

## DNS

 - `uv_ares_init_options`: c-ares integration initialize and terminate
 - `uv_ares_destroy`: destroy c-ares integration
 - `uv_getaddrinfo`: Asynchronous getaddrinfo(3).
 - `uv_freeaddrinfo`: cleanup

## Event Loop functions

 * `uv_run`: starts a loop and blocks till it's done
 * `uv_ref`, `uv_unref`: Manually modify the event loop's reference count.
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

## Misc and Utility

 - `uv_guess_handle`: Used to detect what type of stream should be used with a
    given file descriptor.  For isatty() functionality use this function and
    test for UV_TTY.
 - `uv_std_handle`: ??
 - `uv_queue_work`: generic work queue hook
 * `uv_exepath`: find the path of the executable
 * `uv_get_free_memory`:
 * `uv_get_total_memory`:
 * `uv_loadavg`:

--------------------------------------------------------------------------------

# Userdata Types

Indentation denotes inheritance

- `luv_handle`: Generic handle
    - `luv_udp`: a plain udp handle
    - `luv_fs_watcher`: a filesystem watcher
    - `luv_timer`:
    - `luv_process`: represents a sub proces
    - `luv_stream`: a fifo stream of data
        - `luv_tcp`: a tcp network connection
        - `luv_pipe`: a named socket or domain socket
        - `luv_tty`: the terminal as a stream/socket

