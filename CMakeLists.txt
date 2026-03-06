cmake_minimum_required(VERSION 3.16)
project(llm_format_examples CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(basic_format examples/basic_format.cpp)
target_include_directories(basic_format PRIVATE include)
target_compile_options(basic_format PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall -Wextra>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)

add_executable(nested_schema examples/nested_schema.cpp)
target_include_directories(nested_schema PRIVATE include)
target_compile_options(nested_schema PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall -Wextra>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)

add_executable(validate_only examples/validate_only.cpp)
target_include_directories(validate_only PRIVATE include)
target_compile_options(validate_only PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall -Wextra>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)
