{
  'targets': [
    {
      'target_name': 'luvit',
      'type': 'executable',
      'dependencies': [
        'deps/http-parser/http_parser.gyp:http_parser',
        'deps/luajit.gyp:*',
        'deps/uv/uv.gyp:uv',
      ],
      'sources': [
        'src/lconstants.c',
        'src/lenv.c',
        'src/lhttp_parser.c',
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
        'src/luvit.c',
        'src/lyajl.c',
        'src/utils.c',
        'lib/dns.lua',
        'lib/emitter.lua',
        'lib/error.lua',
        'lib/fiber.lua',
        'lib/fs.lua',
        'lib/http.lua',
        'lib/luvit.lua',
        'lib/mime.lua',
        'lib/net.lua',
        'lib/path.lua',
        'lib/pipe.lua',
        'lib/process.lua',
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
      ],

    'msvs-settings': {
        'VCLinkerTool': {
          'SubSystem': 1, # /subsystem:console
        },
      },
      'conditions': [
        ['OS == "linux"', { 'libraries': ['-ldl'] } ],
      ],
      'defines': [
        'LUVIT_OS="<(OS)"',
      ],
      'include_dirs': [
        'src',
        'deps/uv/src/ares'
      ],
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
  ],
}
