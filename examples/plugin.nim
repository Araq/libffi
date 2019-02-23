# Compile with: nim c --noMain --app:lib plugin.nim
proc hello(x: int) {.exportc.} =
  echo "Hello world, ", x

proc highFive(): int {.exportc.} =
  result = 5
  echo "Here you go!"
