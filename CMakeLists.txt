# @file
# @author aka-sps
# @copyright Syntacore, 2021

cmake_minimum_required(VERSION 3.13)

project(coremark
    VERSION 1.0.1
    LANGUAGES C
)

enable_testing()

if(NOT CMAKE_HOST_WIN32 AND CMAKE_COMPILER_IS_GNUCC)
    find_program(CCACHE_FOUND ccache)

    if(CCACHE_FOUND)
        set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
        set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache) # Less useful to do it for linking, see edit2
    endif(CCACHE_FOUND)
endif(NOT CMAKE_HOST_WIN32 AND CMAKE_COMPILER_IS_GNUCC)

# Configuarble build parameters
set(ITERATIONS 0 CACHE STRING "ITERATIONS")
set(MEM_METHOD STATIC CACHE STRING "MEM_METHOD")
set_property(CACHE MEM_METHOD PROPERTY STRINGS STATIC MALLOC STACK)

# Select port directory
if(PORT_DIR)
    add_subdirectory(${PORT_DIR})
else(PORT_DIR)
    if(MSVC OR CMAKE_SYSTEM_NAME MATCHES "^(CYGWIN|Darwin|FreeBSD|Linux)\$")
        add_subdirectory(posix)
    else()
        message(SEND_ERROR "PLEASE define PORT_DIR! (e.g. make PORT_DIR=simple) for CMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}")
    endif()
endif(PORT_DIR)

# Common definitions
add_library(${PROJECT_NAME} INTERFACE)
target_link_libraries(${PROJECT_NAME} INTERFACE core_portme)
target_sources(${PROJECT_NAME}
    INTERFACE
    core_list_join.c
    core_main.c
    core_matrix.c
    core_state.c
    core_util.c
    coremark.h
)
target_include_directories(${PROJECT_NAME} INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})

# compile options string
set(FLAGS_STR
    ${CMAKE_C_FLAGS}
    $<$<CONFIG:Debug>:${CMAKE_C_FLAGS_DEBUG}>
    $<$<CONFIG:Release>:${CMAKE_C_FLAGS_RELEASE}>
    $<$<CONFIG:RelWithDebInfo>:${CMAKE_C_FLAGS_RELWITH}>
    $<$<CONFIG:MinSizeRel>:${CMAKE_C_FLAGS_MINSIZE}>
)
target_compile_definitions(${PROJECT_NAME}
    INTERFACE
    ITERATIONS=${ITERATIONS}
    FLAGS_STR="$<JOIN:${FLAGS_STR}, >"
    MEM_METHOD=MEM_${MEM_METHOD}
    MEM_LOCATION="${MEM_METHOD}"
)

# 3 variants of executable
foreach(stage 1 2 3)
    add_executable(${PROJECT_NAME}_${stage})
    target_link_libraries(${PROJECT_NAME}_${stage} PUBLIC ${PROJECT_NAME})
endforeach()

if(CMAKE_OBJDUMP)
    set(CMAKE_OBJDUMP_FLAGS "-wxCpS" CACHE STRING "objdump options")

    function(add_dump target)
        add_custom_command(
            TARGET ${target} POST_BUILD
            COMMAND ${CMAKE_OBJDUMP} ${CMAKE_OBJDUMP_FLAGS} $<TARGET_FILE:${target}> > $<TARGET_FILE_BASE_NAME:${target}>.dump
        )
        set_property(TARGET ${target} APPEND PROPERTY ADDITIONAL_CLEAN_FILES $<TARGET_FILE_BASE_NAME:${target}>.dump)
    endfunction(add_dump)

    add_dump(${PROJECT_NAME}_1)
endif(CMAKE_OBJDUMP)

# private compile definitions
target_compile_definitions(${PROJECT_NAME}_1 PUBLIC PERFORMANCE_RUN=1)
target_compile_definitions(${PROJECT_NAME}_2 PUBLIC VALIDATION_RUN=1)

add_custom_target(check
    md5sum -c coremark.md5
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

if(CMAKE_CROSSCOMPILING)
    return()
endif(CMAKE_CROSSCOMPILING)

# rules for test result files
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/run1.log
    COMMAND $<TARGET_FILE:${PROJECT_NAME}_1> 0x0 0x0 0x66 ${ITERATIONS} 7 1 2000 > ${CMAKE_CURRENT_BINARY_DIR}/run1.log
    DEPENDS ${PROJECT_NAME}_1
)
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/run2.log
    COMMAND $<TARGET_FILE:${PROJECT_NAME}_2> 0x3415 0x3415 0x66 ${ITERATIONS} 7 1 2000 > ${CMAKE_CURRENT_BINARY_DIR}/run2.log
    DEPENDS ${PROJECT_NAME}_2 ${CMAKE_CURRENT_BINARY_DIR}/run1.log
)
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/run3.log
    COMMAND $<TARGET_FILE:${PROJECT_NAME}_3> 8 8 8 ${ITERATIONS} 7 1 1200 > ${CMAKE_CURRENT_BINARY_DIR}/run3.log
    DEPENDS ${PROJECT_NAME}_3
)

# performace test and print result target
add_custom_target(print_performance
    ${CMAKE_COMMAND} -E cat ${CMAKE_CURRENT_BINARY_DIR}/run1.log
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/run1.log
)

# perforamce test and print result target
add_custom_target(print_validation DEPENDS print_performance ${CMAKE_CURRENT_BINARY_DIR}/run2.log)
add_custom_target(gen_pgo_data DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/run3.log)

add_custom_target(run ALL
    ${CMAKE_COMMAND} -E echo "Check run1.log and run2.log for results."
    DEPENDS print_performance print_validation
)

add_test(NAME performance
    COMMAND $<TARGET_FILE:${PROJECT_NAME}_1> 0x0 0x0 0x66 ${ITERATIONS} 7 1 2000
)
add_test(NAME validation
    COMMAND $<TARGET_FILE:${PROJECT_NAME}_2> 0x3415 0x3415 0x66 ${ITERATIONS} 7 1 2000
)
