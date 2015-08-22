--[[

LuaJIT FFI-based binding to the nanomsg library

    Copyright (c) 2013 Evan Wies <evan at neomantra dot net>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom
    the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.

--------------------------------------------------------------------------------
TODO: DOCUMENTATION

TODO: zero-copy interface
TODO: device
TODO: nicer interfaces (especially for sockopts, a la ljsyscall?)

--]]

local ffi = require 'ffi'

local int_sz      = ffi.sizeof('int')
local int_1_t     = ffi.typeof('int[1]')
local size_1_t    = ffi.typeof("size_t[1]")
local charptr_1_t = ffi.typeof('char *[1]')
local voidptr_1_t = ffi.typeof('void*[1]')

local names = {
  ["Linux-arm"] = "libnanomsg.so",
  ["Linux-x64"] = "libnanomsg.so",
  ["OSX-x64"] = "libnanomsg.dylib",
  ['Windows-x86'] = 'nanomsg.dll',
}

local arch = ffi.os .. "-" .. ffi.arch
local libnn = module:action(arch .. "/" .. names[arch], function (path)
  return ffi.load(path)
end)

-- Public API
local nn = {}


-- Bind nn_symbol to extract the nanomsg public symbols
ffi.cdef([[
const char* nn_symbol (int i, int *value);
]])
nn.E = {}
do
    local symbol = ffi.new( 'struct { int value[1]; const char* name; }' )
    local i = 0
    while true do
        symbol.name = libnn.nn_symbol( i, symbol.value )
        if symbol.name == nil then break end
        local name = ffi.string( symbol.name )

        -- convert NN_FOO to just FOO, since nn.FOO is nicer than nn.NN_FOO
        name = name:match('NN_([%w_]*)') or name
        nn[ name ] = symbol.value[0]

        -- store mapping of error value -> symbol in nn.E
        if name:match('^E([%w_]*)') then
            nn.E[ symbol.value[0] ] = name
        end
        i = i + 1
    end
end

-- nanomsg ABI check
-- we match the cdef's to the nanomsg library version
if (nn.VERSION_CURRENT  - nn.VERSION_AGE) == 0 then
    ffi.cdef([[
    int nn_errno (void);
    const char *nn_strerror (int errnum);
    void nn_term (void);

    void *nn_allocmsg (size_t size, int type);
    int nn_freemsg (void *msg);

    int nn_socket (int domain, int protocol);
    int nn_close (int s);
    int nn_setsockopt (int s, int level, int option, const void *optval, size_t optvallen);
    int nn_getsockopt (int s, int level, int option, void *optval, size_t *optvallen);
    int nn_bind (int s, const char *addr);
    int nn_connect (int s, const char *addr);
    int nn_shutdown (int s, int how);
    int nn_send (int s, const void *buf, size_t len, int flags);
    int nn_recv (int s, void *buf, size_t len, int flags);

    int nn_device (int s1, int s2);

    // nn_socket_t doesn't exist in nanomsg; it is a metatype anchor for nn.socket
    struct nn_socket_t { int fd; bool close_on_gc; };

    // nn_msg_t doesn't exist in nanomsg; it is a metatype anchor for nn.msg
    struct nn_msg_t { void *ptr; size_t size; };
    ]])
else
    error( "unknown nanomsg version: " .. tostring(nn.VERSION) )
end


-- NN_MSG doesn't come through the symbol interface properly due to its use of size_t
nn.MSG = ffi.typeof('size_t')( -1 )


-- give clients access to the C API
nn.C = libnn


--- terminates the nanomsg library
function nn.term()
    libnn.nn_term()
end


--- returns the current errno, as known by the nanomsg library
function nn.errno()
    return libnn.nn_errno()
end


--- returns a Lua string associated with the passed err code
--- if called without argument, err is retrieved from nn_errno()
function nn.strerror( err )
    err = err or libnn.nn_errno()
    return ffi.string( libnn.nn_strerror( err ) )
end


--- nanomsg socket class
nn.socket = ffi.metatype( 'struct nn_socket_t', {

    --- Construct a new nanomsg socket
    --
    -- nn.socket( protocol, options )
    -- @tparam number protocol The nanomsg protocol
    -- @tparam table options An options table
    -- @return a socket object or nil on error
    -- @return error code if the first argument is nil
    --
    -- The following options are available:
    --    close_on_gc     invoke nn_close when the socket is gc'd (default is true)
    --    domain          either nn.AF_SP or nn.AF_SP_RAW (default is nn.AF_SP)
    --
    __new = function( socket_ct, protocol, options )
        if not protocol then return nil, nn.EINVAL end
        local close_on_gc, domain
        if not options then
            close_on_gc = true
            domain = nn.AF_SP
        else
            if type(options) ~= 'table' then return nil, nn.EINVAL end
            close_on_gc = (options.close_on_gc or options.close_on_gc == nil) and true or false
            domain = options.domain or nn.AF_SP
        end

        local fd = libnn.nn_socket( domain, protocol )
        if fd < 0 then return nil, libnn.nn_errno() end
        return ffi.new( socket_ct, fd, close_on_gc )
    end,

    -- garbage collection destructor, not invoked by user
    __gc = function( s )
        -- make sure the socket is closed
        if s.close_on_gc and s.fd >= 0 then
            libnn.nn_close( s.fd )
        end
    end,

    -- methods
    __index = {

        setsockopt = function( s, level, opt, optval, optvallen )
            if not optvallen and type(optval) == 'boolean' then
                optval    = int_1_t(optval and 1 or 0)
                optvallen = int_sz
            end
            if not optvallen and type(optval) == 'number' then
                optval    = int_1_t(optval)
                optvallen = int_sz
            end
            if not optvallen and type(optval) == 'string' then
                optvallen = #optval
            end
            local rc = libnn.nn_setsockopt( s.fd, level, opt, optval, optvallen )
            if rc == 0 then return rc else return nil, libnn.nn_errno() end
        end,

        -- currently assumes that the returned value is a number
        getsockopt = function( s, level, opt )
            local optval, optvallen = int_1_t(), size_1_t(int_sz)
            local rc = libnn.nn_getsockopt( s.fd, level, opt, optval, optvallen )
            if rc == 0 then return optval[0] else return nil, libnn.nn_errno() end
        end,

        bind = function( s, addr )
            local rc = libnn.nn_bind( s.fd, addr )
            if rc >= 0 then return rc else return nil, libnn.nn_errno() end
        end,

        connect = function( s, addr )
            local rc = libnn.nn_connect( s.fd, addr )
            if rc >= 0 then return rc else return nil, libnn.nn_errno() end
        end,

        shutdown = function( s, how )
            local rc = libnn.nn_shutdown( s.fd, how )
            if rc == 0 then return rc else return nil, libnn.nn_errno() end
        end,

        close = function( s )
            local rc = libnn.nn_close( s.fd )
            if rc < 0 then return nil, libnn.nn_errno() end
            s.fd = -1
            return rc
        end,

        send = function( s, buf, len, flags )
            flags = flags or 0
            local sz = libnn.nn_send( s.fd, buf, len, flags )
            if sz >= 0 then
                return sz
            else
                local err = libnn.nn_errno()
                if err ~= nn.EAGAIN then return nil, err end
                return -1
            end
        end,

        recv = function( s, buf, len, flags )
            flags = flags or 0
            local sz = libnn.nn_recv( s.fd, buf, len, flags )
            if sz >= 0 then
                return sz
            else
                local err = libnn.nn_errno()
                if err ~= nn.EAGAIN then return nil, err end
                return -1
            end
        end,

        -- Sends the passed nn.msg on the socket using zero-copy
        -- The msg is not usable after passed to this function
        -- On success, returns the number of bytes sent and clears msg.ptr
        -- If the message cannot be sent right away, returns -1.
        -- Otherwise, returns nil, nn_errorno()
        send_zc = function( s, msg, flags )
            flags = flags or 0
            local msg_ptr_addr = voidptr_1_t(msg.ptr)
            local sz = libnn.nn_send( s.fd, msg_ptr_addr, nn.MSG, flags )
            if sz >= 0 then
                msg.ptr = nil
                return sz
            else
                local err = libnn.nn_errno()
                if err ~= nn.EAGAIN then return nil, err end
                return -1
            end
        end,

        -- Calls nn_recv on the socket using zero-copy
        -- Returns a nn.msg to access the data
        -- If nn_recv fails, returns nil, nn_errorno()
        recv_zc = function( s, flags )
            flags = flags or 0
            local ptr = charptr_1_t()
            local sz = libnn.nn_recv( s.fd, ptr, nn.MSG, flags )
            if sz < 0 then return nil, libnn.nn_errno() end
            return nn.msg( ptr[0], sz )
        end,
    }
})


--- nanomsg msg class
-- this class sets up automatic management of messages that are allocated
-- by nanomsg, be it through nn_allocmsg or from send/recv with nn.MSG
nn.msg = ffi.metatype( 'struct nn_msg_t', {

    -- constructor
    __new = function( msg_ct, ptr, size )
        return ffi.new( msg_ct, ptr, size )
    end,

    -- destructor
    __gc = function( m )
        if m.ptr ~= nil then
            libnn.nn_freemsg( m.ptr )
        end
    end,

    __len = function( m )
        return m.size
    end,

    -- methods
    __index = {
        --- free the buffer associated with this msg, instead of waiting for GC
        -- sets ptr to NULL
        free = function( m )
            if m.ptr ~= nil then
                libnn.nn_freemsg( m.ptr )
                m.ptr = nil
            end
        end,

        tostring = function( m )
            return ffi.string( m.ptr, m.size )
        end,
    },
})


-- Allocates a buffer for zero-copy using nn_allocmsg
-- This is managed by the Lua GC.
-- Do not invoke nn_freemsg on it directly, but rather nn.msg:free()
nn.allocmsg = function( msg_size, msg_type )
    msg_type = msg_type or 0
    local ptr = libnn.nn_allocmsg( msg_size, msg_type or 0 )
    if ptr == nil then return nil, libnn.nn_errno() end
    return nn.msg( ptr, msg_size )
end


-- Return public API
return nn

