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
      ['OS == "linux" or OS == "freebsd" or OS == "solaris"', {
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
        ],
      }],
      ['OS == "win"', {
        'defines': [
          'LUA_BUILD_AS_DLL',
        ],
      }],
      ['OS=="solaris"', {
        'cflags': ['-pthreads'],
        'ldflags': ['-pthreads'],
      }],
      ['OS=="freebsd"', {
        'cflags': ['-pthread'],
        'ldflags': ['-pthread'],
      }],
      ],
    },

    'targets': [
    {
      'target_name': 'luajit',
      'type': 'executable',
      'dependencies': [
        'buildvm',
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
          '../deps/luajit/src/jit/bc.lua',
          '../deps/luajit/src/jit/bcsave.lua',
          '../deps/luajit/src/jit/dis_arm.lua',
          '../deps/luajit/src/jit/dis_ppc.lua',
          '../deps/luajit/src/jit/dis_x86.lua',
          '../deps/luajit/src/jit/dis_x64.lua',
          '../deps/luajit/src/jit/dump.lua',
          '../deps/luajit/src/jit/v.lua',
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
        'buildvm',
      ],
      'variables': {
        'lj_sources': [
          'luajit/src/lib_aux.c',
          'luajit/src/lib_base.c',
          'luajit/src/lib_bit.c',
          'luajit/src/lib_debug.c',
          'luajit/src/lib_ffi.c',
          'luajit/src/lib_math.c',
          'luajit/src/lib_init.c',
          'luajit/src/lib_io.c',
          'luajit/src/lib_jit.c',
          'luajit/src/lib_os.c',
          'luajit/src/lib_package.c',
          'luajit/src/lib_string.c',
          'luajit/src/lib_table.c',
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
        'luajit/src/ljamalg.c',
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
      'target_name': 'minilua',
      'type': 'executable',
      'sources': [
        'luajit/src/host/minilua.c',
      ],
      'include_dirs': [
        '<(INTERMEDIATE_DIR)',
        'luajit/src',
      ],
    },
    {
      'target_name': 'buildvm',
      'type': 'executable',
      'dependencies': [
        'minilua',
      ],
      'sources': [
        'luajit/src/host/buildvm.c',
        'luajit/src/host/buildvm_asm.c',
        'luajit/src/host/buildvm_peobj.c',
        'luajit/src/host/buildvm_lib.c',
        'luajit/src/host/buildvm_fold.c',
        '<(INTERMEDIATE_DIR)/buildvm_arch.h',
      ],
      'include_dirs': [
        '<(INTERMEDIATE_DIR)',
        'luajit/src',
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
      'actions': [
      {
        'action_name': 'generate_host_buildvm_arch',
        'outputs': ['<(INTERMEDIATE_DIR)/buildvm_arch.h'],
        'inputs': [ '<(PRODUCT_DIR)/minilua' ],
        'variables': {
          'conditions': [
            ['target_arch == "ia32" or target_arch == "x64"', {
              'DASM_ARCH': 'x86'
            }],
            ['target_arch == "arm"', {
              'DASM_ARCH': 'arm'
            }],
            ['target_arch == "x64" and OS != "win"', {
               'DASM_FLAGS': ['-D', 'P64']
            }],
            ['OS == "win"', {
               'DASM_FLAGS': ['-D', 'WIN', '-L']
            }],
          ],
          'DASM_FLAGS': [ '-D', 'JIT', '-D', 'FPU', '-D', 'FFI' ],
        },
        'action': [
          '<(PRODUCT_DIR)/minilua', 'luajit/dynasm/dynasm.lua', '<@(DASM_FLAGS)', '-o', '<(INTERMEDIATE_DIR)/buildvm_arch.h', 'luajit/src/vm_<(DASM_ARCH).dasc'
          ]
      },
      ],
    },
    ],
}


