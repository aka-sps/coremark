cmake_minimum_required(VERSION 3.13)

add_library(core_portme INTERFACE)
target_include_directories(core_portme INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
target_sources(core_portme INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/core_portme.c
                                     ${CMAKE_CURRENT_SOURCE_DIR}/core_portme.h)
target_link_libraries(core_portme INTERFACE rt)

set(MULTITHREAD
    0
    CACHE STRING "Multithread")

if(MULTITHREAD)
  set(MULTITHREAD_TYPE
      PTHREAD
      CACHE STRING "Multithread type")
  set_property(CACHE MULTITHREAD_TYPE PROPERTY STRINGS PTHREAD FORK SOCKET)
  target_compile_definitions(core_portme INTERFACE MULTITHREAD=${MULTITHREAD}
                                                   USE_${MULTITHREAD_TYPE})

  if(MULTITHREAD_TYPE MATCHES "PTHREAD")
    find_package(Threads REQUIRED)
    target_link_libraries(core_portme INTERFACE Threads::Threads)
  endif()
endif(MULTITHREAD)
