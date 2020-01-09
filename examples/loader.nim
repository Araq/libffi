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

# We need to set up our call first. This procedure takes one int argument
var
  cif: Tcif
  params: ParamList
# The argument the procedure takes
params[0] = type_sint64.addr
# Prepare the call, with the aforementioned params, and no return type
if OK != prep_cif(cif, DEFAULT_ABI, 1, type_void.addr, params):
  echo "Something went wrong with preparing the statement"
  quit 1

# Now let's set up a list of arguments
var args: ArgList
var i = 100
args[0] = i.addr

# And call the symbol with our argument
call(cif, procSym, nil, args)

# Let's do another one. This time without arguments, but with a return type
if OK != prep_cif(cif, DEFAULT_ABI, 0, type_sint64.addr, params):
  echo "Something went wrong with preparing the statement"
  quit 1

# Again load the symbol
var highFiveSym = dll.symAddr("highFive")

# Set up the position of our return value and call the procedure
var theFive = 0
call(cif, highFiveSym, theFive.addr, args)
echo theFive

