set(CMAKE_CUDA_STANDARD 14)
set(CMAKE_CUDA_STANDARD_REQUIRED 14)

list(APPEND CMAKE_CUDA_FLAGS "--extended-lambda --expt-relaxed-constexpr -Xcudafe --display_error_number  -Xcudafe --diag_suppress=3159")
# This avoids a warning in NVCC 11.x or later
#list(APPEND CMAKE_CUDA_FLAGS "-Xcudafe --diag_suppress=20208")

# now using a "new" way of handling CUDA
add_executable(fmt-in-cuda-test cuda-cpp14.cu cpp14.cc)
set_target_properties(fmt-in-cuda-test PROPERTIES CUDA_SEPARABLE_COMPILATION ON)
target_compile_features(fmt-in-cuda-test PRIVATE cxx_std_14)
add_executable(fmt-in-cuda-kernel-test fmt-in-cuda-kernel.cu)
target_compile_features(fmt-in-cuda-kernel-test PRIVATE cxx_std_14)
#list(APPEND CMAKE_CUDA_FLAGS "--expt-relaxed-constexpr")
if (MSVC)
# with MSVC, 'cxx_std_14' will only propagate to the host code (MSVC), but will
# not set __cplusplus correctly anyway, while nvcc will ignore it.
# If specified for nvcc on the command line as '-std=c++14' nvcc will emit this
# message instead:
# nvcc warning : The -std=c++14 flag is not supported with the configured host
#                compiler. Flag will be ignored.
set_property(SOURCE cuda-cpp14.cu APPEND PROPERTY
  COMPILE_OPTIONS -Xcompiler /std:c++14 -Xcompiler /Zc:__cplusplus)
set_property(SOURCE cpp14.cc APPEND PROPERTY
  COMPILE_OPTIONS /std:c++14 /Zc:__cplusplus)
endif()

set_property(TARGET fmt-in-cuda-kernel-test PROPERTY CUDA_STANDARD 14)
# TODO: Replace the following with a rule, in the main fmt CMakeLists, which mandates this flag for CUDA compilation
target_compile_options(fmt-in-cuda-kernel-test PRIVATE "--expt-relaxed-constexpr")

get_target_property(IN_USE_CUDA_STANDARD fmt-in-cuda-test CUDA_STANDARD)
message(STATUS "cuda_standard:          ${IN_USE_CUDA_STANDARD}")

get_target_property(IN_USE_CUDA_STANDARD_REQUIRED
    fmt-in-cuda-test CUDA_STANDARD_REQUIRED)
message(STATUS "cuda_standard_required: ${IN_USE_CUDA_STANDARD_REQUIRED}")

# We don't use PUBLIC or other keyword for reasons explained in the
# CUDA_LINK_LIBRARIES_KEYWORD section in
# https://cmake.org/cmake/help/latest/module/FindCUDA.html
target_link_libraries(fmt-in-cuda-test fmt::fmt)
target_link_libraries(fmt-in-cuda-kernel-test fmt::fmt)

