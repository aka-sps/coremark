cmake_minimum_required(VERSION 3.13)

add_library(core_portme INTERFACE)
target_include_directories(core_portme INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
target_sources(core_portme INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/core_portme.c)
target_link_libraries(core_portme INTERFACE rt)
