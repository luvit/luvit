#!/usr/bin/env python

import os
import subprocess
import sys

# TODO: release/debug

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if sys.platform != "win32":
    cmd = ['make', '-C', 'out']
else:
    cmd = ['tools\win_build.bat']

print ' '.join(cmd)
sys.exit(subprocess.call(cmd, shell=True))
