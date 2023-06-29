import importlib.resources as impr
import shutil
import subprocess
import os
import sys


def build():
    exe = shutil.which("cmake")
    if not exe:
        raise FileNotFoundError("CMake not available")

    with impr.as_file(impr.files(__package__).joinpath("CMakeLists.txt")) as f:
        s = f.parent
        b = s / "build"
        g = []
        if sys.platform == "win32" and not os.environ.get("CMAKE_GENERATOR"):
            g = ["-G", "MinGW Makefiles"]
        subprocess.check_call([exe, f"-S{s}", f"-B{b}"] + g)
        subprocess.check_call([exe, "--build", str(b), "--parallel"])
