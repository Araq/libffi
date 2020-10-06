# Package
version       = "1.0.4"
author        = "Andreas Rumpf"
description   = "libffi wrapper for Nim."
license       = "MIT"

when defined(windows):
  installExt     = @["nim", "c", "h", "s"]

# Dependencies
requires "nim >= 0.10.0"
