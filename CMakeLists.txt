cmake_minimum_required(VERSION 3.13)

project(coremark C)

if(CMAKE_SYSTEM_NAME MATCHES "^(CYGWIN|Darwin|FreeBSD|Linux)\$")
  add_subdirectory(posix)
else()
  message(
    SEND_ERROR
      "PLEASE define PORT_DIR! (e.g. make PORT_DIR=simple) for CMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}"
  )
endif()

set(MEM_METHOD STATIC CACHE STRING "MEM_METHOD")
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
target_sources(${PROJECT_NAME} INTERFACE core_list_join.c core_main.c
                                         core_matrix.c core_state.c core_util.c)
target_include_directories(${PROJECT_NAME}
                           INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_definitions(
  ${PROJECT_NAME}
  INTERFACE ITERATIONS=${ITERATIONS} FLAGS_STR="$<JOIN:${FLAGS_STR}, >"
            MEM_METHOD=MEM_${MEM_METHOD}
            MEM_LOCATION="${MEM_METHOD}")
target_link_libraries(${PROJECT_NAME} INTERFACE core_portme)

set(PARAM1 0x0 0x0 0x66 ${ITERATIONS})
set(PARAM2 0x3415 0x3415 0x66 ${ITERATIONS})

set(run1.log-PARAM ${PARAM1} 7 1 2000)
set(run2.log-PARAM ${PARAM2} 7 1 2000)

add_executable(${PROJECT_NAME}_1)
target_compile_definitions(${PROJECT_NAME}_1 PUBLIC PERFORMANCE_RUN=1)

add_executable(${PROJECT_NAME}_2)
target_compile_definitions(${PROJECT_NAME}_2 PUBLIC VALIDATION_RUN=1)

foreach(stage 1 2)
  target_link_libraries(${PROJECT_NAME}_${stage} PUBLIC ${PROJECT_NAME})
  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/run${stage}.log
    COMMAND $<TARGET_FILE:${PROJECT_NAME}_${stage}> >
            ${CMAKE_CURRENT_BINARY_DIR}/run${stage}.log
    DEPENDS ${PROJECT_NAME}_${stage})
endforeach(stage)

add_custom_target(
  run ALL
  COMMAND @echo "Check run1.log and run2.log for results."
  COMMAND @echo "See README.md for run and reporting rules."
  DEPENDS run1.log run2.log)
