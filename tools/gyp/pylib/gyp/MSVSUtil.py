# Copyright (c) 2013 Google Inc. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Utility functions shared amongst the Windows generators."""

import copy

def _ShardName(name, number):
  """Add a shard number to the end of a target.

  Arguments:
    name: name of the target (foo#target)
    number: shard number
  Returns:
    Target name with shard added (foo_1#target)
  """
  parts = name.rsplit('#', 1)
  parts[0] = '%s_%d' % (parts[0], number)
  return '#'.join(parts)


def ShardTargets(target_list, target_dicts):
  """Shard some targets apart to work around the linkers limits.

  Arguments:
    target_list: List of target pairs: 'base/base.gyp:base'.
    target_dicts: Dict of target properties keyed on target pair.
  Returns:
    Tuple of the new sharded versions of the inputs.
  """
  # Gather the targets to shard, and how many pieces.
  targets_to_shard = {}
  for t in target_dicts:
    shards = int(target_dicts[t].get('msvs_shard', 0))
    if shards:
      targets_to_shard[t] = shards
  # Shard target_list.
  new_target_list = []
  for t in target_list:
    if t in targets_to_shard:
      for i in range(targets_to_shard[t]):
        new_target_list.append(_ShardName(t, i))
    else:
      new_target_list.append(t)
  # Shard target_dict.
  new_target_dicts = {}
  for t in target_dicts:
    if t in targets_to_shard:
      for i in range(targets_to_shard[t]):
        name = _ShardName(t, i)
        new_target_dicts[name] = copy.copy(target_dicts[t])
        new_target_dicts[name]['target_name'] = _ShardName(
             new_target_dicts[name]['target_name'], i)
        sources = new_target_dicts[name].get('sources', [])
        new_sources = []
        for pos in range(i, len(sources), targets_to_shard[t]):
          new_sources.append(sources[pos])
        new_target_dicts[name]['sources'] = new_sources
    else:
      new_target_dicts[t] = target_dicts[t]
  # Shard dependencies.
  for t in new_target_dicts:
    dependencies = copy.copy(new_target_dicts[t].get('dependencies', []))
    new_dependencies = []
    for d in dependencies:
      if d in targets_to_shard:
        for i in range(targets_to_shard[d]):
          new_dependencies.append(_ShardName(d, i))
      else:
        new_dependencies.append(d)
    new_target_dicts[t]['dependencies'] = new_dependencies

  return (new_target_list, new_target_dicts)
