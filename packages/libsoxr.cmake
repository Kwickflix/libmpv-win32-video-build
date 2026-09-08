ExternalProject_Add(libsoxr
    GIT_REPOSITORY https://gitlab.com/shinchiro/soxr.git
    SOURCE_DIR ${SOURCE_LOCATION}
    UPDATE_COMMAND ""
    GIT_CLONE_FLAGS "--filter=tree:0"
    CONFIGURE_COMMAND ${EXEC} CONF=1 cmake -H<SOURCE_DIR> -B<BINARY_DIR>
        -G Ninja
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DCMAKE_INSTALL_PREFIX=${MINGW_INSTALL_PREFIX}
        -DCMAKE_FIND_ROOT_PATH=${MINGW_INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS=OFF
        # Kwick (W-083): libsoxr's CMakeLists declares
        #   cmake_minimum_required (VERSION 3.1 FATAL_ERROR)
        # and CMake 4 removed compatibility with anything below 3.5, so the
        # configure step fails outright. CMAKE_POLICY_VERSION_MINIMUM is the
        # escape hatch CMake 4 provides for exactly this. Pinning is no help
        # here - the 3.1 floor is on master and has been for years.
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
        -DBUILD_TESTS=OFF
        -DWITH_OPENMP=OFF
        -DHAVE_WORDS_BIGENDIAN_EXITCODE=1
    BUILD_COMMAND ${EXEC} ninja -C <BINARY_DIR>
    INSTALL_COMMAND ${EXEC} ninja -C <BINARY_DIR> install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(libsoxr)
cleanup(libsoxr install)
