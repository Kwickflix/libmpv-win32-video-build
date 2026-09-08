ExternalProject_Add(libvpl
    GIT_REPOSITORY https://github.com/oneapi-src/oneVPL.git
    # Kwick (W-083): PIN to 2023-09-24. oneapi-src/oneVPL has since been renamed
    # and restructured (the repo now reports itself as "libvpl"), and this
    # recipe's -DBUILD_* options were written for the older layout. At
    # ca5bbbb0 the CMake floor is 3.13.0, so CMake 4.4.3 is still happy with it.
    GIT_TAG ca5bbbb057a6e84b103aca807612afb693ad046c
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} CONF=1 cmake -H<SOURCE_DIR> -B<BINARY_DIR>
        -G Ninja
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DCMAKE_INSTALL_PREFIX=${MINGW_INSTALL_PREFIX}
        -DCMAKE_FIND_ROOT_PATH=${MINGW_INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_DISPATCHER=ON
        -DBUILD_DEV=ON
        -DBUILD_PREVIEW=OFF
        -DBUILD_TOOLS=OFF
        -DBUILD_TOOLS_ONEVPL_EXPERIMENTAL=OFF
        -DINSTALL_EXAMPLE_CODE=OFF
        -DBUILD_TESTS=OFF
    BUILD_COMMAND ${EXEC} ninja -C <BINARY_DIR>
    INSTALL_COMMAND ${EXEC} ninja -C <BINARY_DIR> install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(libvpl)
cleanup(libvpl install)
