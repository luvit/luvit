{
  'variables': {
    'YAJL_MAJOR': '2',
    'YAJL_MINOR': '0',
    'YAJL_MICRO': '5',
  },
  'targets': [
    {
      'target_name': 'yajl',
      'type': '<(library)',
      'sources': [
        'yajl/src/yajl.c',
        'yajl/src/yajl_alloc.c',
        'yajl/src/yajl_buf.c',
        'yajl/src/yajl_encode.c',
        'yajl/src/yajl_gen.c',
        'yajl/src/yajl_lex.c',
        'yajl/src/yajl_parser.c',
        'yajl/src/yajl_tree.c',
        'yajl/src/yajl_version.c',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          '<(SHARED_INTERMEDIATE_DIR)',
        ]
      },
      'include_dirs': [
        'yajl/src',
        '<(SHARED_INTERMEDIATE_DIR)',
      ],
      'copies': [
        {
          'destination': '<(SHARED_INTERMEDIATE_DIR)/yajl',
          'files': [
            'yajl/src/api/yajl_common.h',
            'yajl/src/api/yajl_gen.h',
            'yajl/src/api/yajl_parse.h',
            'yajl/src/api/yajl_tree.h',
          ]
        }
      ],
      'actions': [
        {
          'variables': {
            'replacements': [
              '{YAJL_MAJOR}:<(YAJL_MAJOR)',
              '{YAJL_MINOR}:<(YAJL_MINOR)',
              '{YAJL_MICRO}:<(YAJL_MICRO)',
            ]
          },
          'action_name': 'version_header',
          'inputs': [
            'yajl/src/api/yajl_version.h.cmake'
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/yajl/yajl_version.h',
          ],
          'action': [
            '../tools/lame_sed.py',
            '<@(_inputs)',
            '<@(_outputs)',
            '<@(replacements)',
          ],
        }
      ]
    }, # end libyajl
  ] # end targets
}
