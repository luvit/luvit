{
  'targets': [
    {'target_name': 'libluvit',
     'type': 'static_library',
     'dependencies': [
       'deps/http-parser/http_parser.gyp:http_parser',
       'deps/luajit.gyp:*',
       'deps/yajl.gyp:yajl',
       'deps/uv/uv.gyp:uv',
     ],
     'export_dependent_settings': [
       'deps/http-parser/http_parser.gyp:http_parser',
       'deps/luajit.gyp:*',
       'deps/yajl.gyp:yajl',
       'deps/uv/uv.gyp:uv',
      ],
      'conditions': [
        ['OS=="linux" or OS=="freebsd" or OS=="openbsd" or OS=="solaris"', {
          'cflags': [ '--std=c89' ],
          'defines': [ '_GNU_SOURCE' ]
        }],
      ],
     'sources': [
       'src/lconstants.c',
       'src/lenv.c',
       'src/lhttp_parser.c',
       'src/lyajl.c',
       'src/los.c',
       'src/luv.c',
       'src/luv_fs.c',
       'src/luv_fs_watcher.c',
       'src/luv_dns.c',
       'src/luv_handle.c',
       'src/luv_misc.c',
       'src/luv_pipe.c',
       'src/luv_process.c',
       'src/luv_stream.c',
       'src/luv_tcp.c',
       'src/luv_timer.c',
       'src/luv_tty.c',
       'src/luv_udp.c',
       'src/luvit_init.c',
       'src/luvit_exports.c',
       'src/lyajl.c',
       'src/utils.c',
       'lib/buffer.lua',
       'lib/dns.lua',
       'lib/emitter.lua',
       'lib/error.lua',
       'lib/fiber.lua',
       'lib/fs.lua',
       'lib/handle.lua',
       'lib/http.lua',
       'lib/json.lua',
       'lib/luvit.lua',
       'lib/mime.lua',
       'lib/net.lua',
       'lib/object.lua',
       'lib/path.lua',
       'lib/pipe.lua',
       'lib/process.lua',
       'lib/querystring.lua',
       'lib/repl.lua',
       'lib/request.lua',
       'lib/response.lua',
       'lib/stack.lua',
       'lib/stream.lua',
       'lib/tcp.lua',
       'lib/timer.lua',
       'lib/tty.lua',
       'lib/udp.lua',
       'lib/url.lua',
       'lib/utils.lua',
       'lib/watcher.lua',
     ],
     'defines': [
       'LUVIT_OS="<(OS)"',
       'LUVIT_VERSION="<!(git --git-dir .git describe --tags)"',
       'HTTP_VERSION="<!(git --git-dir deps/http-parser/.git describe --tags)"',
       'UV_VERSION="<!(git --git-dir deps/uv/.git describe --all --tags --always --long)"',
       'LUAJIT_VERSION="<!(git --git-dir deps/luajit/.git describe --tags)"',
       'YAJL_VERSIONISH="<!(git --git-dir deps/yajl/.git describe --tags)"',
     ],
     'include_dirs': [
       'src',
       'deps/uv/src/ares'
     ],
     'direct_dependent_settings': {
       'include_dirs': [
         'src',
         'deps/uv/src/ares'
       ]
     },
     'rules': [
       {
         'rule_name': 'jit_lua',
         'extension': 'lua',
         'outputs': [
           '<(SHARED_INTERMEDIATE_DIR)/generated/<(RULE_INPUT_ROOT)_jit.c'
         ],
         'action': [
           '<(PRODUCT_DIR)/luajit',
           '-b', '<(RULE_INPUT_PATH)',
           '<(SHARED_INTERMEDIATE_DIR)/generated/<(RULE_INPUT_ROOT)_jit.c',
         ],
         'process_outputs_as_sources': 1,
         'message': 'luajit <(RULE_INPUT_PATH)'
       }
     ],
    },
    {
      'target_name': 'luvit',
      'type': 'executable',
      'dependencies': [
        'libluvit',
        'deps/luajit.gyp:*',
        'deps/uv/uv.gyp:uv',
      ],
      'sources': [
        'src/luvit_main.c',
        'src/luvit_exports.c',
      ],
      'msvs-settings': {
        'VCLinkerTool': {
          'SubSystem': 1, # /subsystem:console
        },
      },
      'conditions': [
        ['OS == "linux"', {
          'libraries': ['-ldl'],
        }],
        ['OS=="linux" or OS=="freebsd" or OS=="openbsd" or OS=="solaris"', {
          'cflags': [ '--std=c89' ],
          'defines': [ '_GNU_SOURCE' ]
        }],
      ],
    },
  ],
}
