{
  'targets': [
    {'target_name': 'libluvit',
     'type': 'static_library',
     'dependencies': [
       'deps/http-parser/http_parser.gyp:http_parser',
       'deps/luajit.gyp:luajit',
       'deps/luajit.gyp:libluajit',
       'deps/yajl.gyp:yajl',
       'deps/yajl.gyp:copy_headers',
       'deps/uv/uv.gyp:uv',
       'deps/zlib/zlib.gyp:zlib',
       'deps/luacrypto.gyp:luacrypto',
     ],
     'export_dependent_settings': [
       'deps/http-parser/http_parser.gyp:http_parser',
       'deps/luajit.gyp:luajit',
       'deps/luajit.gyp:libluajit',
       'deps/yajl.gyp:yajl',
       'deps/uv/uv.gyp:uv',
       'deps/luacrypto.gyp:luacrypto',
      ],
      'conditions': [
        ['OS=="linux" or OS=="freebsd" or OS=="openbsd" or OS=="solaris"', {
          'cflags': [ '--std=c89' ],
          'defines': [ '_GNU_SOURCE' ]
        }],
        ['"<(without_ssl)" == "false"', {
          'sources': [
            'src/luv_tls.c',
            'src/luv_tls_conn.c',
          ],
          'dependencies': [
            'deps/openssl/openssl.gyp:openssl'
          ],
          'export_dependent_settings': [
            'deps/openssl/openssl.gyp:openssl'
          ],
          'defines': [ 'USE_OPENSSL' ],
        }],
      ],
     'sources': [
       'src/lconstants.c',
       'src/lenv.c',
       'src/lhttp_parser.c',
       'src/luv_buffer.c',
       'src/lyajl.c',
       'src/los.c',
       'src/luv.c',
       'src/luv_fs.c',
       'src/luv_fs_watcher.c',
       'src/luv_dns.c',
       'src/luv_debug.c',
       'src/luv_handle.c',
       'src/luv_misc.c',
       'src/luv_pipe.c',
       'src/luv_process.c',
       'src/luv_stream.c',
       'src/luv_tcp.c',
       'src/luv_timer.c',
       'src/luv_tty.c',
       'src/luv_udp.c',
       'src/luv_zlib.c',
       'src/luvit_init.c',
       'src/lyajl.c',
       'src/utils.c',
       'lib/luvit/buffer.lua',
       'lib/luvit/childprocess.lua',
       'lib/luvit/core.lua',
       'lib/luvit/dgram.lua',
       'lib/luvit/dns.lua',
       'lib/luvit/fiber.lua',
       'lib/luvit/fs.lua',
       'lib/luvit/http.lua',
       'lib/luvit/https.lua',
       'lib/luvit/json.lua',
       'lib/luvit/luvit.lua',
       'lib/luvit/mime.lua',
       'lib/luvit/module.lua',
       'lib/luvit/net.lua',
       'lib/luvit/path.lua',
       'lib/luvit/querystring.lua',
       'lib/luvit/repl.lua',
       'lib/luvit/stack.lua',
       'lib/luvit/timer.lua',
       'lib/luvit/tls.lua',
       'lib/luvit/url.lua',
       'lib/luvit/utils.lua',
       'lib/luvit/uv.lua',
       'lib/luvit/zlib.lua',
     ],
     'defines': [
       'LUVIT_OS="<(OS)"',
       'LUVIT_VERSION="<!(git --git-dir .git describe --tags)"',
       'HTTP_VERSION="<!(git --git-dir deps/http-parser/.git describe --tags)"',
       'UV_VERSION="<!(git --git-dir deps/uv/.git describe --all --tags --always --long)"',
       'LUAJIT_VERSION="<!(git --git-dir deps/luajit/.git describe --tags)"',
       'YAJL_VERSIONISH="<!(git --git-dir deps/yajl/.git describe --tags)"',
       'BUNDLE=1',
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
           '-b', '-g', '<(RULE_INPUT_PATH)',
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
        ['"<(without_ssl)" == "false"', {
          'defines': [ 'USE_OPENSSL' ],
        }],
      ],
      'defines': [ 'BUNDLE=1' ]
    },
    {
      'target_name': 'vector_luvit',
      'product_name': 'vector',
      'product_extension': 'luvit',
      'product_prefix': '',
      'type': 'shared_library',
      'dependencies': [
        'libluvit',
      ],
      'sources': [
        'examples/native/vector.c'
      ],
      'conditions': [
        ['OS=="linux" or OS=="freebsd" or OS=="openbsd" or OS=="solaris"', {
          'cflags': [ '--std=c89' ],
          'defines': [ '_GNU_SOURCE' ]
        }],
      ],
    },
    {
      'target_name': 'install',
      'type': 'none',
      'copies': [
        {
          'destination': '<(luvit_prefix)/bin',
          'files': [
            'out/Debug/luvit'
          ]
        },
        {
          'destination': '<(luvit_prefix)/lib/luvit',
          'files': [
            'lib/luvit/buffer.lua',
            'lib/luvit/childprocess.lua',
            'lib/luvit/core.lua',
            'lib/luvit/dns.lua',
            'lib/luvit/fiber.lua',
            'lib/luvit/fs.lua',
            'lib/luvit/http.lua',
            'lib/luvit/https.lua',
            'lib/luvit/json.lua',
            'lib/luvit/luvit.lua',
            'lib/luvit/mime.lua',
            'lib/luvit/module.lua',
            'lib/luvit/net.lua',
            'lib/luvit/path.lua',
            'lib/luvit/querystring.lua',
            'lib/luvit/repl.lua',
            'lib/luvit/stack.lua',
            'lib/luvit/timer.lua',
            'lib/luvit/tls.lua',
            'lib/luvit/url.lua',
            'lib/luvit/utils.lua',
            'lib/luvit/uv.lua',
            'lib/luvit/zlib.lua'
          ]
        },
        {
          'destination': '<(luvit_prefix)/include/luvit/luajit',
          'files': [
            'deps/luajit/src/lua.h',
            'deps/luajit/src/lauxlib.h',
            'deps/luajit/src/luaconf.h',
            'deps/luajit/src/luajit.h',
            'deps/luajit/src/lualib.h'
          ]
        },
        {
          'destination': '<(luvit_prefix)/include/luvit/http_parser',
          'files': [
            'deps/http-parser/http_parser.h'
          ]
        },
        {
          'destination': '<(luvit_prefix)/include/luvit/uv',
          'files': [
            'deps/uv/include/'
          ]
        },
        {
          'destination': '<(luvit_prefix)/include/luvit',
          'files': [
            'src/lconstants.h',
            'src/lenv.h',
            'src/lhttp_parser.h',
            'src/luv_buffer.h',
            'src/los.h',
            'src/luv.h',
            'src/luv_debug.h',
            'src/luv_dns.h',
            'src/luv_fs.h',
            'src/luv_fs_watcher.h',
            'src/luv_handle.h',
            'src/luv_misc.h',
            'src/luv_pipe.h',
            'src/luv_portability.h',
            'src/luv_process.h',
            'src/luv_stream.h',
            'src/luv_tcp.h',
            'src/luv_timer.h',
            'src/luv_tls.h',
            'src/luv_tls_root_certs.h',
            'src/luv_tty.h',
            'src/luv_udp.h',
            'src/luv_zlib.h',
            'src/luvit.h',
            'src/luvit_exports.h',
            'src/luvit_init.h',
            'src/lyajl.h',
            'src/utils.h'
          ]
        }
      ]
    }
  ],
}
