-- This file documents the main object classes and their respective methods
-- TODO: generate this from source

return {
  Object = { 
    class_methods = {
      "new(...)",
      "extend()",
    },
  },
  Emitter = {
    parent = "Object",
    methods = {
      "on(name, callback)",
      "emit(name, ...)",
      "once(name, callback)",
      "remove_listener(name, callback)",
      "missing_handler_type(name, ...)",
    }
  },
  Handle = {
    parent = "Emitter",
    methods = {
      "close()",
      "add_handler_type(name)",
      "set_handler(name, callback)",
    }
  },
  Stream = {
    parent = "Handle",
    methods = {
      "shutdown()",
      "listen(callback)",
      "accept(other_stream)",
      "read_start()",
      "read_stop()",
      "write(chunk, callback)",
      "pipe(target)",
    }
  },
  TCP = {
    parent = "Stream",
    class_methods = {
      "create_server(ip, port, on_connection)",
    },
    methods = {
      "initialize()",
      "nodelay(enable)",
      "keepalive(enable, delay)",
      "bind(host, port)",
      "bind6(host, port"),
      "getsockname()",
      "getpeername()",
      "connect(ip_address, port)",
      "connect6(ip_address, port)",
    }
  },
  Pipe = {
    parent = "Stream",
    methods = {
      "initialize(ipc)",
      "open(fd)",
      "bind(name)",
      "connect(name)",      
    }
  },
  TTY = {
    parent = "Stream",
    class_methods = {
      "reset_mode()",
    },
    methods = {
      "initialize(fd, readable)",
      "set_mode(mode)",
      "get_winsize()",
    }
  },
  HttpRequest = {
    parent = "Stream",
  },
  HttpResponse = {
    parent = "Stream",
  },
  UDP = {
    parent = "Handle",
    methods = {
      "initialize()",
      "bind(host, port)",
      "bind6(host, port)",
      "set_membership(multicast_addr, interface_addr, option)",
      "getsockname()",
      "send(...)",
      "send6(...)",
      "recv_start()",
      "recv_stop()",
    }
  },
  Timer = {
    parent = "Handle",
    class_methods = {
      "set_timeout(duration, callback, ...)",
      "set_interval(interval, callback, ...)",
      "clear_timer(timer)",
    },
    methods = {
      "initialize()",
      "start(timeout, interval)",
      "stop()",
      "again()",
      "set_repeat(interval)",
      "get_repeat()",
    }
  },
  Process = {
    parent = "Handle",
    class_methods = {
      "spawn(command, args, options)",
    },
    methods = {
      "initialize(command, args, options)",
      "kill(signal)",
    }
  },
  Error {
    parent = "Object",
    methods = {
      "initialize(message)",
    },
  },
}

