{
  'variables': {
    'conditions': [
      ['OS == "win"', {
        'asm_format': 'peobj',
          'lj_vm': '<(INTERMEDIATE_DIR)/luajit/src/lj_vm.obj',
      }],
      ['OS == "mac"', {
        'asm_format': 'machasm',
        'lj_vm': '<(INTERMEDIATE_DIR)/luajit/src/lj_vm.s',
      }],
      ['OS == "linux"', {
        'asm_format': 'elfasm',
        'lj_vm': '<(INTERMEDIATE_DIR)/luajit/src/lj_vm.s',
      }]
    ]
  },
    'target_defaults': {
      'defines': [
        'LUAJIT_ENABLE_LUA52COMPAT',
      'LUA_USE_APICHECK',
      ],
      'conditions': [
        ['target_arch=="x64"', {
          'defines': [
            'LUAJIT_TARGET=LUAJIT_ARCH_x64',
          ],
        }],
      ['target_arch=="ia32"', {
        'defines': [
          'LUAJIT_TARGET=LUAJIT_ARCH_x86',
        ],
      }],
      ['OS != "win"', {
        'defines': [
          '_LARGEFILE_SOURCE',
          '_FILE_OFFSET_BITS=64',
          '_GNU_SOURCE',
          'EIO_STACKSIZE=262144'
        ],
      }],
      ['OS == "win"', {
        'defines': [
          'LUA_BUILD_AS_DLL',
        ],
      }],
      ['OS=="solaris"', {
        'cflags': ['-pthreads'],
        'ldlags': ['-pthreads'],
      }],
      ],
    },

    'targets': [
    {
      'target_name': 'luajit',
      'type': 'executable',
      'dependencies': [
        'libluajit',
        'luajit-datafiles',
      ],
      'conditions': [
        ['OS == "linux"', { 'libraries': ['-ldl'] }, ],
      ],
      'sources': [
        'luajit/src/luajit.c',
      ]
    },
  {
    'target_name': 'luajit-datafiles',
    'type': 'none',
    'copies': [
     {
       'destination': '<(PRODUCT_DIR)/lua/jit',
       'files': [
          '../deps/luajit/lib/bc.lua',
          '../deps/luajit/lib/bcsave.lua',
          '../deps/luajit/lib/dis_arm.lua',
          '../deps/luajit/lib/dis_ppc.lua',
          '../deps/luajit/lib/dis_x86.lua',
          '../deps/luajit/lib/dis_x64.lua',
          '../deps/luajit/lib/dump.lua',
          '../deps/luajit/lib/v.lua',
      ]
    }],
  },
    {
      'target_name': 'libluajit',
      'conditions': [
        ['OS == "win"', { 'type': 'shared_library' },
          { 'type': 'static_library' } ],
      ],
      'dependencies': [
        'buildvm#host',
      ],
      'variables': {
        'lj_sources': [
          'luajit/src/lib_base.c',
          'luajit/src/lib_math.c',
          'luajit/src/lib_bit.c',
          'luajit/src/lib_string.c',
          'luajit/src/lib_table.c',
          'luajit/src/lib_io.c',
          'luajit/src/lib_os.c',
          'luajit/src/lib_package.c',
          'luajit/src/lib_debug.c',
          'luajit/src/lib_jit.c',
          'luajit/src/lib_ffi.c',
        ]
      },
      'include_dirs': [
        '<(INTERMEDIATE_DIR)',
        'luajit/src',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          '<(INTERMEDIATE_DIR)',
          'luajit/src',
        ]
      },
      'sources': [
        '<(lj_vm)',
        'luajit/src/lib_aux.c',
        'luajit/src/lib_init.c',
        'luajit/src/lib_base.c',
        'luajit/src/lib_math.c',
        'luajit/src/lib_string.c',
        'luajit/src/lib_table.c',
        'luajit/src/lib_io.c',
        'luajit/src/lib_os.c',
        'luajit/src/lib_package.c',
        'luajit/src/lib_debug.c',
        'luajit/src/lib_bit.c',
        'luajit/src/lib_jit.c',
        'luajit/src/lib_ffi.c',
        'luajit/src/lj_gc.c',
        'luajit/src/lj_alloc.c',
        'luajit/src/lj_api.c',
        'luajit/src/lj_asm.c',
        'luajit/src/lj_bc.c',
        'luajit/src/lj_bcread.c',
        'luajit/src/lj_bcwrite.c',
        'luajit/src/lj_carith.c',
        'luajit/src/lj_ccall.c',
        'luajit/src/lj_ccallback.c',
        'luajit/src/lj_cconv.c',
        'luajit/src/lj_cdata.c',
        'luajit/src/lj_char.c',
        'luajit/src/lj_clib.c',
        'luajit/src/lj_cparse.c',
        'luajit/src/lj_crecord.c',
        'luajit/src/lj_ctype.c',
        'luajit/src/lj_debug.c',
        'luajit/src/lj_dispatch.c',
        'luajit/src/lj_err.c',
        'luajit/src/lj_ffrecord.c',
        'luajit/src/lj_func.c',
        'luajit/src/lj_gdbjit.c',
        'luajit/src/lj_ir.c',
        'luajit/src/lj_lex.c',
        'luajit/src/lj_lib.c',
        'luajit/src/lj_mcode.c',
        'luajit/src/lj_meta.c',
        'luajit/src/lj_obj.c',
        'luajit/src/lj_opt_dce.c',
        'luajit/src/lj_opt_fold.c',
        'luajit/src/lj_opt_loop.c',
        'luajit/src/lj_opt_mem.c',
        'luajit/src/lj_opt_narrow.c',
        'luajit/src/lj_opt_split.c',
        'luajit/src/lj_parse.c',
        'luajit/src/lj_record.c',
        'luajit/src/lj_snap.c',
        'luajit/src/lj_state.c',
        'luajit/src/lj_str.c',
        'luajit/src/lj_tab.c',
        'luajit/src/lj_trace.c',
        'luajit/src/lj_udata.c',
        'luajit/src/lj_vmevent.c',
        'luajit/src/lj_vmmath.c',
        '<(INTERMEDIATE_DIR)/lj_libdef.h',
        '<(INTERMEDIATE_DIR)/lj_recdef.h',
        '<(INTERMEDIATE_DIR)/lj_folddef.h',
        '<(INTERMEDIATE_DIR)/lj_vmdef.h',
        '<(INTERMEDIATE_DIR)/lj_ffdef.h',
        '<(INTERMEDIATE_DIR)/lj_bcdef.h',
      ],
      'actions': [
      {
        'action_name': 'generate_lj_libdef',
        'outputs': ['<(INTERMEDIATE_DIR)/lj_libdef.h'],
        'inputs': [ '<(PRODUCT_DIR)/buildvm' ],
        'action': [
          '<(PRODUCT_DIR)/buildvm', '-m', 'libdef', '-o', '<(INTERMEDIATE_DIR)/lj_libdef.h', '<@(lj_sources)'
          ]
      },
      {
        'action_name': 'generate_lj_recdef',
        'outputs': ['<(INTERMEDIATE_DIR)/lj_recdef.h'],
        'inputs': [ '<(PRODUCT_DIR)/buildvm' ],
        'action': [
          '<(PRODUCT_DIR)/buildvm', '-m', 'recdef', '-o', '<(INTERMEDIATE_DIR)/lj_recdef.h', '<@(lj_sources)'
          ]
      },
      {
        'action_name': 'generate_lj_folddef',
        'outputs': ['<(INTERMEDIATE_DIR)/lj_folddef.h'],
        'inputs': [ '<(PRODUCT_DIR)/buildvm' ],
        'action': [
          '<(PRODUCT_DIR)/buildvm', '-m', 'folddef', '-o', '<(INTERMEDIATE_DIR)/lj_folddef.h', 'luajit/src/lj_opt_fold.c'
          ]
      },
      {
        'action_name': 'generate_lj_vmdef',
        'outputs': ['<(INTERMEDIATE_DIR)/vmdef.lua'],
        'inputs': [ '<(PRODUCT_DIR)/buildvm' ],
        'action': [
          '<(PRODUCT_DIR)/buildvm', '-m', 'vmdef', '-o', '<(INTERMEDIATE_DIR)/vmdef.lua', '<@(lj_sources)'
          ]
      },
      {
        'action_name': 'generate_lj_ffdef',
        'outputs': ['<(INTERMEDIATE_DIR)/lj_ffdef.h'],
        'inputs': [ '<(PRODUCT_DIR)/buildvm' ],
        'action': [
          '<(PRODUCT_DIR)/buildvm', '-m', 'ffdef', '-o', '<(INTERMEDIATE_DIR)/lj_ffdef.h', '<@(lj_sources)'
          ]
      },
      {
        'action_name': 'generate_lj_bcdef',
        'outputs': ['<(INTERMEDIATE_DIR)/lj_bcdef.h'],
        'inputs': [ '<(PRODUCT_DIR)/buildvm' ],
        'action': [
          '<(PRODUCT_DIR)/buildvm', '-m', 'bcdef', '-o', '<(INTERMEDIATE_DIR)/lj_bcdef.h', '<@(lj_sources)'
          ]
      },
      {
        'action_name': 'generate_lj_vm',
        'outputs': ['<(lj_vm)'],
        'inputs': [ '<(PRODUCT_DIR)/buildvm' ],
        'action': [
          '<(PRODUCT_DIR)/buildvm', '-m', '<(asm_format)', '-o', '<(lj_vm)'
          ]
      }
      ],
    },
    {
      'target_name': 'buildvm',
      'type': 'executable',
      'toolsets': ['host'],
      'sources': [
        'luajit/src/buildvm.c',
        'luajit/src/buildvm_asm.c',
        'luajit/src/buildvm_peobj.c',
        'luajit/src/buildvm_lib.c',
        'luajit/src/buildvm_fold.c',
      ],
      'rules': [
      {
        'rule_name': 'generate_header_from_dasc',
        'extension': 'dasc',
        'outputs': [
          'luajit/src/<(RULE_INPUT_ROOT).h'
          ],
        'action': [
          '<(PRODUCT_DIR)/lua',
        'luajit/dynasm/dynasm.lua',
        '-LN',
        '-o', 'luajit/src/<(RULE_INPUT_ROOT).h',
        '<(RULE_INPUT_PATH)'
          ],
        'process_outputs_as_sources': 0,
        'message': 'dynasm <(RULE_INPUT_PATH)'
      }
      ],
    },
    ],
}


