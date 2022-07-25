# Cross-compilation setup
#
# This file is passed to cmake on the command line via
# -DCMAKE_TOOLCHAIN_FILE.  It gets read first, prior to any of cmake's
# system tests.
#
# This is the place to configure your cross-compiling environment.
# An example for using the riscv 32/64 baremetal toolchain is given below.
#
set(CMAKE_SYSTEM_NAME Linux)
if(NOT DEFINED TARGET_PREFIX)
    set(TARGET_PREFIX riscv64-unknown-linux-gnu-)
endif()

# RISC-V Cross-compilation setup common part
if(NOT DEFINED CROSS_PATH)
    if(NOT DEFINED ENV{CROSS_PATH})
        message ("CROSS_PATH variable not set, default is used: /opt/syntacore/riscv-gcc/bin")
        set(ENV{CROSS_PATH} "/opt/syntacore/riscv-gcc/bin")
    endif()
    set(RISCV $ENV{CROSS_PATH})
endif()

set(CROSS_PATH $ENV{CROSS_PATH})

set(CMAKE_FIND_ROOT_PATH ${CROSS_PATH})
set(CMAKE_SYSTEM_PROCESSOR riscv)

# search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(CMAKE_C_COMPILER ${CMAKE_FIND_ROOT_PATH}/${TARGET_PREFIX}gcc${CMAKE_HOST_EXECUTABLE_SUFFIX} CACHE FILEPATH "C compiler path")
set(CMAKE_CXX_COMPILER ${CMAKE_FIND_ROOT_PATH}/${TARGET_PREFIX}g++${CMAKE_HOST_EXECUTABLE_SUFFIX} CACHE FILEPATH "CXX compiler path")
set(CMAKE_OBJDUMP ${CMAKE_FIND_ROOT_PATH}/${TARGET_PREFIX}objdump${CMAKE_HOST_EXECUTABLE_SUFFIX} CACHE FILEPATH "Objdump path")
set(CMAKE_OBJCOPY ${CMAKE_FIND_ROOT_PATH}/${TARGET_PREFIX}objcopy${CMAKE_HOST_EXECUTABLE_SUFFIX} CACHE FILEPATH "Objcopy path")
# set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS)
# set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS)

if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.20" AND CMAKE_HOST_SYSTEM_NAME MATCHES "CYGWIN" AND CMAKE_GENERATOR MATCHES "Makefiles|WMake")
    set(CMAKE_DEPENDS_USE_COMPILER FALSE)
    message(NOTICE "For MinGW tools in Cygwin: restore legacy behavior: using CMake for dependencies discovery")
endif()
