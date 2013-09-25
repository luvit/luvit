# Copyright (c) 2013 Google Inc. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
{
  'targets': [
    {
      'target_name': 'shared',
      'type': 'shared_library',
      'sources': [ 'file.c' ],
    },
    {
      'target_name': 'static',
      'type': 'static_library',
      'sources': [ 'file.c' ],
    },
    {
      'target_name': 'shared_executable',
      'type': 'executable',
      'sources': [ 'main.c' ],
      'dependencies': [
        'shared',
      ]
    },
    {
      'target_name': 'static_executable',
      'type': 'executable',
      'sources': [ 'main.c' ],
      'dependencies': [
        'static',
      ]
    },
  ],
}
