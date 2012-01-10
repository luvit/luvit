#!/usr/bin/env python

import os
import subprocess
import sys

# TODO: release/debug

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
build_dir = os.path.join(root, 'out')

def build():
  if sys.platform != "win32":
      cmd = 'make -C %s' % build_dir
  else:
      cmd = 'tools\win_build.bat'

  print cmd
  sys.exit(subprocess.call(cmd, shell=True))

def test():
  luvit = os.path.join(root, 'out', 'Debug', 'luvit')
  test_dir = os.path.join(root, 'tests')
  old_cwd = os.getcwd()
  os.chdir(test_dir)
  cmd = '%s runner.lua' % luvit
  print cmd
  rc = subprocess.call(cmd, shell=True)
  os.chdir(old_cwd)
  sys.exit(rc)

commands = {
  'build': build,
  'test': test,
}

def usage():
  print('Usage: build.py [%s]' % ', '.join(commands.keys()))
  sys.exit(1)

if len(sys.argv) != 2:
  usage()

ins = sys.argv[1]
if not commands.has_key(ins):
  print('Invalid command: %s' % ins)
  sys.exit(1)

print('Running %s' % ins)
cmd = commands.get(ins)
cmd()

