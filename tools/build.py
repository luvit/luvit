#!/usr/bin/env python

import os
import subprocess
import sys
import shutil

# TODO: release/debug

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
build_dir = os.path.join(root, 'out')

def build():
  if sys.platform.find('freebsd') == 0:
      cmd = 'gmake -C %s' % build_dir
  elif sys.platform != "win32":
      cmd = 'make -C %s' % build_dir
  else:
      cmd = 'tools\win_build.bat'

  print cmd
  sys.exit(subprocess.call(cmd, shell=True))

def test():
  if sys.platform == "win32":
    luvit = os.path.join(root, 'Debug', 'luvit.exe')
  else:
    luvit = os.path.join(root, 'out', 'Debug', 'luvit')

  test_dir = os.path.join(root, 'tests')
  test_tmp_dir = 'tmp'
  old_cwd = os.getcwd()
  os.chdir(test_dir)

  try:
    os.mkdir(test_tmp_dir)
  except OSError:
    pass

  cmd = '%s runner.lua' % luvit
  print cmd
  rc = subprocess.call(cmd, shell=True)
  shutil.rmtree(test_tmp_dir)
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

