ExternalProject_Add(fontconfig
    DEPENDS
        expat
        freetype2
        zlib
        libiconv
    GIT_REPOSITORY https://gitlab.freedesktop.org/fontconfig/fontconfig.git
    SOURCE_DIR ${SOURCE_LOCATION}
    UPDATE_COMMAND ""
    # Kwick (W-083): PIN to 2023-09-21. Floating on main broke the patch:
    #   Applying: Custom changes for mpv builds
    #   error: sha1 information is lacking or useless (src/fcdir.c).
    # git am --3way cannot fall back either, because the clone is blobless
    # (--filter=tree:0) so the pre-image blobs are not present.
    # GIT_REMOTE_NAME removed - see xxhash.cmake; left set it resets to @{u}
    # every build and undoes the pin.
    GIT_TAG a264a2c0ca0be120c0fd2325f0d67ca4d5e81bd0
    GIT_CLONE_FLAGS "--filter=tree:0"
    PATCH_COMMAND ${EXEC} git am --3way ${CMAKE_CURRENT_SOURCE_DIR}/fontconfig-*.patch
    CONFIGURE_COMMAND ${EXEC} CONF=1 meson setup <BINARY_DIR> <SOURCE_DIR>
        --prefix=${MINGW_INSTALL_PREFIX}
        --libdir=${MINGW_INSTALL_PREFIX}/lib
        --cross-file=${MESON_CROSS}
        --buildtype=release
        --default-library=static
        -Ddoc=disabled
        -Dtests=disabled
        -Dtools=disabled
        -Dcache-build=disabled
    BUILD_COMMAND ${EXEC} ninja -C <BINARY_DIR>
    INSTALL_COMMAND ${EXEC} ninja -C <BINARY_DIR> install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(fontconfig)
force_meson_configure(fontconfig)
cleanup(fontconfig install)
