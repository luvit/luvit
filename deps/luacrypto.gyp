{
  'targets': [
    {
      'target_name': 'luacrypto',
      'type': '<(library)',
      'dependencies': [
        'openssl/openssl.gyp:openssl',
        'luajit.gyp:*',
      ],
      'sources': [
        'luacrypto/src/lcrypto.c',
      ],
      'include_dirs': [
        'luacrypto/src',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          'luacrypto/src',
        ]
      },
      'conditions': [
        ['OS == "linux"', {
          'libraries': ['-ldl'],
        }],
        ['OS=="linux" or OS=="freebsd" or OS=="openbsd" or OS=="solaris"', {
          'cflags': [ '--std=c89' ],
          'defines': [ '_GNU_SOURCE' ]
        }],
        ['OS=="mac"', {
          'xcode_settings': {
            'GCC_C_LANGUAGE_STANDARD': 'c89',
          }
        }],
      ],
    }
  ],
}

