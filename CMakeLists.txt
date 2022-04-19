cmake_minimum_required(VERSION 3.13)

project(coremark C)

message("CMAKE_SYSTEM_PROCESSOR=${CMAKE_SYSTEM_PROCESSOR} CMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}")

if(CMAKE_SYSTEM_PROCESSOR MATCHES "^riscv64\$" AND CMAKE_SYSTEM_NAME MATCHES "^Linux\$")
  add_subdirectory(rv64-linux)
elseif(CMAKE_SYSTEM_NAME MATCHES "^(CYGWIN|Darwin|FreeBSD|Linux)\$")
  add_subdirectory(posix)
else()
  message(
    SEND_ERROR
      "PLEASE define PORT_DIR! (e.g. make PORT_DIR=simple) for CMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}"
  )
endif()

set(MEM_METHOD
    STATIC
    CACHE STRING "MEM_METHOD")
set_property(CACHE MEM_METHOD PROPERTY STRINGS STATIC MALLOC STACK)

set(ITERATIONS
    0
    CACHE STRING "ITERATIONS")
set(FLAGS_STR
    ${CMAKE_C_FLAGS}
    $<$<CONFIG:Debug>:${CMAKE_C_FLAGS_DEBUG}>
    $<$<CONFIG:Release>:${CMAKE_C_FLAGS_RELEASE}>
    $<$<CONFIG:RelWithDebInfo>:${CMAKE_C_FLAGS_RELWITH}>
    $<$<CONFIG:MinSizeRel>:${CMAKE_C_FLAGS_MINSIZE}>)

add_library(${PROJECT_NAME} INTERFACE)
target_sources(
  ${PROJECT_NAME} INTERFACE core_list_join.c core_main.c core_matrix.c
                            core_state.c core_util.c coremark.h)
target_include_directories(${PROJECT_NAME}
                           INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_definitions(
  ${PROJECT_NAME}
  INTERFACE ITERATIONS=${ITERATIONS} FLAGS_STR="$<JOIN:${FLAGS_STR}, >"
            MEM_METHOD=MEM_${MEM_METHOD} MEM_LOCATION="${MEM_METHOD}")
target_link_libraries(${PROJECT_NAME} INTERFACE core_portme)

foreach(stage 1 2 3)
  add_executable(${PROJECT_NAME}_${stage})
  target_link_libraries(${PROJECT_NAME}_${stage} PUBLIC ${PROJECT_NAME})
endforeach()

target_compile_definitions(${PROJECT_NAME}_1 PUBLIC PERFORMANCE_RUN=1)
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/run1.log
  COMMAND $<TARGET_FILE:${PROJECT_NAME}_1> 0x0 0x0 0x66 ${ITERATIONS} 7 1 2000 >
          ${CMAKE_CURRENT_BINARY_DIR}/run1.log
  DEPENDS ${PROJECT_NAME}_1)
add_custom_target(run_performance DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/run1.log)

target_compile_definitions(${PROJECT_NAME}_2 PUBLIC VALIDATION_RUN=1)
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/run2.log
  COMMAND $<TARGET_FILE:${PROJECT_NAME}_2> 0x3415 0x3415 0x66 ${ITERATIONS} 7 1
          2000 > ${CMAKE_CURRENT_BINARY_DIR}/run2.log
  DEPENDS ${PROJECT_NAME}_2 ${CMAKE_CURRENT_BINARY_DIR}/run1.log)
add_custom_target(run_validation DEPENDS run_performance
                                         ${CMAKE_CURRENT_BINARY_DIR}/run2.log)

add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/run3.log
  COMMAND $<TARGET_FILE:${PROJECT_NAME}_3> 8 8 8 ${ITERATIONS} 7 1 1200 >
          ${CMAKE_CURRENT_BINARY_DIR}/run3.log
  DEPENDS ${PROJECT_NAME}_3)
add_custom_target(gen_pgo_data DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/run3.log)

add_custom_target(
  check
  md5sum -c coremark.md5
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

add_custom_target(
  run ALL
  COMMAND @echo "Check run1.log and run2.log for results."
  COMMAND @echo "See README.md for run and reporting rules."
  DEPENDS run_performance run_validation)
