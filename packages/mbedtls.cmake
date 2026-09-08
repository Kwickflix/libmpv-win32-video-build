ExternalProject_Add(mbedtls
    GIT_REPOSITORY https://github.com/Mbed-TLS/mbedtls.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    # Kwick (W-083): `git apply`, not `git am --3way`. `git am` COMMITS each
    # patch, so HEAD moves off the pinned commit; force-update's
    # `git reset --hard` (to the pin, or to HEAD for a floating package) then
    # cannot undo it, the cached src_packages keeps the patched HEAD, and the
    # next run re-applies a patch that is already in. That is what produced
    #   Applying: ...  No changes -- Patch already applied.
    #   error: sha1 information is lacking or useless (meson.build)
    #   Patch failed at 0002 ...                        (exit code 128)
    # on fontconfig five runs running, and it is a trap every `git am` package
    # is one failed run away from. `git apply` touches the working tree only:
    # any reset restores a pristine tree, so the patch step is idempotent and
    # no hand-clearing is ever needed. It also needs no pre-image blob, which
    # these `--filter=tree:0` clones do not have. ffmpeg has always done this.
    # Verified locally at each package's pinned commit, on blobless clones.
    PATCH_COMMAND ${EXEC} git apply ${CMAKE_CURRENT_SOURCE_DIR}/mbedtls-*.patch
    UPDATE_COMMAND ""
    # Kwick (W-083): PIN to 030f11b0, committed 2023-09-24T07:48:47Z - three
    # minutes before media-kit published the release this DLL comes from.
    # Patched package, was floating on master. GIT_REMOTE_NAME removed so
    # force_rebuild_git does not reset the pin to @{u}.
    GIT_TAG 030f11b0b18481b34d95cd9b8ca78d41f35c99d8
    GIT_RESET 1ec69067fa1351427f904362c1221b31538c8b57 # v3.5.0
    CONFIGURE_COMMAND ${EXEC} CONF=1 cmake -H<SOURCE_DIR> -B<BINARY_DIR>
        -G Ninja
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DCMAKE_INSTALL_PREFIX=${MINGW_INSTALL_PREFIX}
        -DCMAKE_FIND_ROOT_PATH=${MINGW_INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS=OFF
        -DENABLE_PROGRAMS=OFF
        -DENABLE_TESTING=OFF
        -DGEN_FILES=ON
        -DUSE_STATIC_MBEDTLS_LIBRARY=ON
        -DUSE_SHARED_MBEDTLS_LIBRARY=OFF
        -DINSTALL_MBEDTLS_HEADERS=ON
        -DMBEDTLS_FATAL_WARNINGS=OFF
        -DCMAKE_C_FLAGS='${CMAKE_C_FLAGS} -mpclmul -msse2 -maes' # needed for i686's target
    BUILD_COMMAND ${EXEC} ninja -C <BINARY_DIR>
    INSTALL_COMMAND ${EXEC} ninja -C <BINARY_DIR> install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(mbedtls)
cleanup(mbedtls install)

set(mbedtls_pc ${MINGW_INSTALL_PREFIX}/lib/pkgconfig/mbedtls.pc)
file(WRITE ${mbedtls_pc}
"prefix=${MINGW_INSTALL_PREFIX}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mbedtls
Description: mbedtls
Version: 3.5.0
Libs: -L\${libdir} -lmbedtls -lmbedx509 -lmbedcrypto
Libs.private: -lbcrypt -lws2_32
Cflags: -I\${includedir}
")
