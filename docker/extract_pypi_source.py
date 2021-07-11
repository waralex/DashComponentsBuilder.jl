import os
import importlib
import sys
import json

package_name = os.environ["PACKAGE_NAME"]
source_dir = os.environ["SOURCE_DIR"]
mod = importlib.import_module(package_name)
mdir = os.path.dirname(mod.__file__)
cmd = 'cp -r ' + mdir + ' ' + source_dir + '/'
print(cmd)
os.system(cmd)
