# Kwick (W-083): both halves of ExternalProject must come from the SAME CMake
# version. This file used to fetch Modules/ExternalProject from the MOVING
# "release/cmake-release" branch while pinning ExternalProject.cmake to v3.26.4.
# Once CMake's release moved past 3.26 the two halves no longer agreed, and
# every git clone died immediately with
#     math cannot parse the expression: "1 + ": syntax error
# because the newer gitclone.cmake.in expects substitutions the 3.26.4
# ExternalProject.cmake never makes. Pin BOTH to v3.31.6 - the version
# packages/cmake-0001-ExternalProject-changes.patch is written against, and the
# version upstream shinchiro/mpv-winbuild-cmake pins.
set(EP_CMAKE_VERSION "v3.31.6")

execute_process(
    COMMAND mkdir -p cmake
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

# The tarball name carries the version so a cached build directory holding the
# old, unpinned download is not silently reused.
if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/modules-${EP_CMAKE_VERSION}.tar.gz")
    execute_process(
        COMMAND curl -sL https://gitlab.kitware.com/cmake/cmake/-/archive/${EP_CMAKE_VERSION}/cmake-${EP_CMAKE_VERSION}.tar.gz?path=Modules/ExternalProject -o modules-${EP_CMAKE_VERSION}.tar.gz
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    execute_process(
        COMMAND tar -C ${CMAKE_CURRENT_BINARY_DIR}/cmake --strip-components=1 -xf modules-${EP_CMAKE_VERSION}.tar.gz
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
endif()

if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/cmake/Modules/ExternalProject.cmake")
    execute_process(
        COMMAND curl -sLO https://gitlab.kitware.com/cmake/cmake/-/raw/${EP_CMAKE_VERSION}/Modules/ExternalProject.cmake
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/cmake/Modules
    )
    execute_process(
        COMMAND patch -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/packages/cmake-0001-ExternalProject-changes.patch
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/cmake
    )
endif()

include(${CMAKE_CURRENT_BINARY_DIR}/cmake/Modules/ExternalProject.cmake)
