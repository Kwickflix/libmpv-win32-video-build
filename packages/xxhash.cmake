ExternalProject_Add(xxhash
    GIT_REPOSITORY https://github.com/Cyan4973/xxHash.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    # Kwick (W-083): PIN to 2023-09-20. This tracked the moving "dev" branch,
    # and xxHash has since moved its CMake files from cmake_unofficial/ to
    # build/cmake/, so the configure step failed with
    #   CMake Error: The source directory ".../xxhash/cmake_unofficial"
    #   does not exist.
    # This commit still has cmake_unofficial and declares
    # cmake_minimum_required(VERSION 3.5), which CMake 4.4.3 still accepts.
    GIT_TAG 9e6c1819df09368b87c0fb25fe5799015d4d681f
    UPDATE_COMMAND ""
    # Kwick (W-083): GIT_REMOTE_NAME removed. force_rebuild_git() treats an
    # unset GIT_REMOTE_NAME as "a commit hash is pinned" and skips the reset;
    # left set, it resets the checkout to @{u} (origin/dev) on every build and
    # silently undoes the pin above.
    CONFIGURE_COMMAND ${EXEC} CONF=1 cmake -H<SOURCE_DIR>/cmake_unofficial -B<BINARY_DIR>
        -G Ninja
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DCMAKE_INSTALL_PREFIX=${MINGW_INSTALL_PREFIX}
        -DCMAKE_FIND_ROOT_PATH=${MINGW_INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS=OFF
        -DDISPATCH=ON
        -DXXHASH_BUILD_XXHSUM=OFF
        -DCMAKE_C_FLAGS='${CMAKE_C_FLAGS} -DXXH_X86DISPATCH_ALLOW_AVX=1'
    BUILD_COMMAND ${EXEC} ninja -C <BINARY_DIR>
    INSTALL_COMMAND ${EXEC} ninja -C <BINARY_DIR> install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(xxhash)
cleanup(xxhash install)
