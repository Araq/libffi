# Compile with: nim c --noMain --app:lib plugin.nim
proc hello(x: int32) {.cdecl, exportc, dynlib.} =
  echo "Hello world, ", x

proc highFive(): int32 {.cdecl, exportc, dynlib.} =
  result = 5
  echo "Here you go!"

proc helloFancy(f: proc (n: int32): int32 {.cdecl.}) {.exportc.} =
  echo "Such fancyness, ", f(42)
