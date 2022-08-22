#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "LICENSE.txt", included in this
#    distribution, for details about the copyright.
#

{.deadCodeElim: on.}
when defined(nimHasStyleChecks):
  {.push styleChecks: off.}

when defined(windows):
  import os

  const libPath = currentSourcePath.parentDir / "libs"

  when defined(cpu64):
    const arch = "win64"
  else:
    const arch = "win32"

  {.pragma: mylib, dynlib: libPath / arch / "libffi-7.dll".}
elif defined(macosx):
  {.pragma: mylib, dynlib: "libffi.dylib".}
else:
  {.pragma: mylib, dynlib: "libffi.so(.7|)".}

type
  Arg* = int
  SArg* = int
{.deprecated: [TArg: Arg, TSArg: SArg].}

when defined(windows) and defined(x86):
  type
    TABI* {.size: sizeof(cint).} = enum
      FIRST_ABI, SYSV, STDCALL

  const DEFAULT_ABI* = SYSV
elif defined(amd64) and defined(windows):
  type
    TABI* {.size: sizeof(cint).} = enum
      FIRST_ABI, WIN64
  const DEFAULT_ABI* = WIN64
else:
  type
    TABI* {.size: sizeof(cint).} = enum
      FIRST_ABI, SYSV, UNIX64

  when defined(i386):
    const DEFAULT_ABI* = SYSV
  else:
    const DEFAULT_ABI* = UNIX64

const
  tkVOID* = 0
  tkINT* = 1
  tkFLOAT* = 2
  tkDOUBLE* = 3
  tkLONGDOUBLE* = 4
  tkUINT8* = 5
  tkSINT8* = 6
  tkUINT16* = 7
  tkSINT16* = 8
  tkUINT32* = 9
  tkSINT32* = 10
  tkUINT64* = 11
  tkSINT64* = 12
  tkSTRUCT* = 13
  tkPOINTER* = 14

  tkLAST = tkPOINTER
  tkSMALL_STRUCT_1B* = (tkLAST + 1)
  tkSMALL_STRUCT_2B* = (tkLAST + 2)
  tkSMALL_STRUCT_4B* = (tkLAST + 3)

type
  Type* = object
    size*: int
    alignment*: uint16
    typ*: uint16
    elements*: ptr UncheckedArray[ptr Type]
{.deprecated: [TType: Type].}

var
  type_void* {.importc: "ffi_type_void", mylib.}: Type
  type_uint8* {.importc: "ffi_type_uint8", mylib.}: Type
  type_sint8* {.importc: "ffi_type_sint8", mylib.}: Type
  type_uint16* {.importc: "ffi_type_uint16", mylib.}: Type
  type_sint16* {.importc: "ffi_type_sint16", mylib.}: Type
  type_uint32* {.importc: "ffi_type_uint32", mylib.}: Type
  type_sint32* {.importc: "ffi_type_sint32", mylib.}: Type
  type_uint64* {.importc: "ffi_type_uint64", mylib.}: Type
  type_sint64* {.importc: "ffi_type_sint64", mylib.}: Type
  type_float* {.importc: "ffi_type_float", mylib.}: Type
  type_double* {.importc: "ffi_type_double", mylib.}: Type
  type_pointer* {.importc: "ffi_type_pointer", mylib.}: Type
  type_longdouble* {.importc: "ffi_type_double", mylib.}: Type

type
  Status* {.size: sizeof(cint).} = enum
    OK, BAD_TYPEDEF, BAD_ABI
  TypeKind* = cuint
  TCif* {.pure, final.} = object
    abi*: TABI
    nargs*: cuint
    argTypes*: ptr ptr Type
    rtype*: ptr Type
    bytes*: cuint
    flags*: cuint
{.deprecated: [Tstatus: Status].}

type
  Raw* = object
    sint*: SArg
{.deprecated: [TRaw: Raw].}

proc raw_call*(cif: var TCif; fn: proc () {.cdecl.}; rvalue: pointer;
               avalue: ptr Raw) {.cdecl, importc: "ffi_raw_call", mylib.}
proc ptrarray_to_raw*(cif: var TCif; args: ptr pointer; raw: ptr Raw) {.cdecl,
    importc: "ffi_ptrarray_to_raw", mylib.}
proc raw_to_ptrarray*(cif: var TCif; raw: ptr Raw; args: ptr pointer) {.cdecl,
    importc: "ffi_raw_to_ptrarray", mylib.}
proc raw_size*(cif: var TCif): int {.cdecl, importc: "ffi_raw_size", mylib.}

proc prep_cif*(cif: var TCif; abi: TABI; nargs: cuint; rtype: ptr Type;
               atypes: ptr ptr Type): Status {.cdecl, importc: "ffi_prep_cif",
    mylib.}
proc call*(cif: var TCif; fn: proc () {.cdecl.}; rvalue: pointer;
           avalue: ptr pointer) {.cdecl, importc: "ffi_call", mylib.}

# the same with an easier interface:
type
  ParamList* = array[0..100, ptr Type]
  ArgList* = array[0..100, pointer]
{.deprecated: [TParamList: ParamList, TArgList: ArgList].}

proc prep_cif*(cif: var TCif; abi: TABI; nargs: cuint; rtype: ptr Type;
               atypes: ParamList): Status {.cdecl, importc: "ffi_prep_cif",
    mylib.}
proc call*(cif: var TCif; fn, rvalue: pointer;
           avalue: ArgList) {.cdecl, importc: "ffi_call", mylib.}


when defined(x8664):
  const TRAMPOLINE_SIZE = 24
elif defined(windows) and defined(x86):
  const TRAMPOLINE_SIZE = 52
elif defined(amd64) and defined(windows):
  const TRAMPOLINE_SIZE = 29
else:
  const TRAMPOLINE_SIZE = 10

type
  ClosureProc = proc (cif: var TCif, ret: pointer, args: UncheckedArray[pointer], user_data: pointer) {.cdecl.}
  Closure* {.pure, final.} = object
    tramp: array[0..TRAMPOLINE_SIZE, uint8]
    cif: ptr TCif
    fun: ClosureProc
    user_data: pointer

proc closure_alloc*(size: int, code: var pointer): ptr Closure {.cdecl, importc: "ffi_closure_alloc", mylib.}
# same but taking care of the size
template closure_alloc*(code: var pointer): ptr Closure =
  closure_alloc(sizeof(Closure), code)
proc closure_free*(closure: ptr Closure) {.cdecl, importc: "ffi_closure_free", mylib.}
proc prep_closure_loc*(closure: ptr Closure, cif: var TCif, fun: ClosureProc, user_data: pointer, codeloc: pointer): Status {.cdecl, importc: "ffi_prep_closure_loc", mylib.}

# Useful for eliminating compiler warnings
##define FFI_FN(f) ((void (*)(void))f)
when defined(nimHasStyleChecks):
  {.pop.} # {.push styleChecks: off.}
