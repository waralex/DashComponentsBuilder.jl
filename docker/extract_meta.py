import os
import importlib
import sys
import json

package_name = os.environ["PACKAGE_NAME"]
source_dir = os.environ["SOURCE_DIR"]
dest_dir = os.environ["DEST_DIR"]
sys.path.insert(0, os.getcwd())
mod = importlib.import_module(package_name)
js_dist = getattr(mod, "_js_dist", [])
css_dist = getattr(mod, "_css_dist", [])
ver = mod.__version__
with open("{dir}/package_meta.json".format(dir = dest_dir), "w") as f:
    json.dump(
        {
            "version" : ver,
            "js_dist" : js_dist,
            "css_dist" : css_dist
        }, f
    )
