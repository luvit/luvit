{
  'targets': [
    {
      'target_name': 'test',
      'type': 'none',
      'actions': [
        {
          'action_name': 'test_runner',
          'inputs': [
            '<(PRODUCT_DIR)/luvit',
            'runner.lua',
          ],
          'outputs': [ '<(PRODUCT_DIR)/test-results.stamp' ],
          'action': [
            '<(PRODUCT_DIR)/luvit',
            'runner.lua',
          ],
        }
      ],
    },
  ]
}
