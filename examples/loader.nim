# Compile with: nim c --passl:-rdynamic -r loader.nim
import os
import dynlib
import libffi
when defined(linux):
  proc dlerror(): cstring {.importc.}
else:
  proc dlerror(): string = "Unknown error"

echo "Trying to load the library at: " & $(getAppDir() / "libplugin.so")
# First let's load a library to find procedures in
var dll = loadLib($(getAppDir() / "libplugin.so"), false)
if dll == nil:
  echo "Something went wrong with loading the plugin:\n" & $dlerror()
  quit 1

# Now let's try and get a symbol from it
var procSym = dll.symAddr("hello")
if procSym == nil:
  echo "Could not get symbol for hello"
  quit 1

# We need to set up our call first. This procedure takes one int argument
var
  cif: Tcif
  params: ParamList
# The argument the procedure takes
params[0] = type_sint32.addr
# Prepare the call, with the aforementioned params, and no return type
if OK != prep_cif(cif, DEFAULT_ABI, 1, type_void.addr, params):
  echo "Something went wrong with preparing the statement"
  quit 1

# Now let's set up a list of arguments
var args: ArgList
var i: int32 = 100
args[0] = i.addr

# And call the symbol with our argument
call(cif, procSym, nil, args)



# Let's do another one. This time without arguments, but with a return type
if OK != prep_cif(cif, DEFAULT_ABI, 0, type_sint32.addr, params):
  echo "Something went wrong with preparing the statement"
  quit 1

# Again load the symbol
var highFiveSym = dll.symAddr("highFive")

# Set up the position of our return value and call the procedure
var theFive: int32 = 0
call(cif, highFiveSym, theFive.addr, args)
echo theFive




# And yet another example. This one with a simple function argument
params[0] = type_pointer.addr
if OK != prep_cif(cif, DEFAULT_ABI, 1, type_void.addr, params):
  echo "Something went wrong with preparing the statement"
  quit 1

var helloFancySym = dll.symAddr("helloFancy")
if helloFancySym == nil:
  echo "Could not get symbol for helloFancy"
  quit 1

# This is the function that will be called
proc fancyTen(x: int32): int32 {.cdecl.} =
  result = 10
  echo "It was given, ", x

var fancyTenPointer: pointer = fancyTen
args[0] = fancyTenPointer.addr
call(cif, helloFancySym, nil, args)



# Now, let's build a function at runtime with the closure API

proc uglyEleven(cif: var TCif, ret: pointer, args: UncheckedArray[pointer], user_data: pointer) {.cdecl.} =
  #long int x = *(long int*)args[0];
  var x = cast[ptr int32](args[0])[]
  var c = cast[ptr int](user_data)[]
  echo "Given: ", x, ", Context: ", c
  cast[ptr int32](ret)[] = 11

var bound: pointer = nil
var closure: ptr Closure = closure_alloc(bound)

# Initialize the cif
if OK != prep_cif(cif, DEFAULT_ABI, 1, type_sint32.addr, params):
  echo "Something went wrong with preparing the statement"
  quit 1

var user_data = 17

if OK != prep_closure_loc(closure, cif, uglyEleven, user_data.addr, bound):
  echo "Something went wrong initializing the closure"
  quit 1

var r = cast[proc (x: int32): int32 {.cdecl.}](bound)(15)
echo "Result, ", r