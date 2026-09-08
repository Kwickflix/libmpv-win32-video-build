ExternalProject_Add(fontconfig
    DEPENDS
        expat
        freetype2
        zlib
        libiconv
    GIT_REPOSITORY https://gitlab.freedesktop.org/fontconfig/fontconfig.git
    SOURCE_DIR ${SOURCE_LOCATION}
    UPDATE_COMMAND ""
    # Kwick (W-083): PIN to c2290882 (2024-02-10). Floating on main broke the
    # patch with
    #   error: sha1 information is lacking or useless (src/fcdir.c).
    # because git am --3way needs the patch's pre-image blob and these clones
    # are blobless (--filter=tree:0).
    #
    # The pin is dated by the PATCH, not by the release. This repo's master is
    # from 2024-02-28 and its patches were rebased for the packages as they
    # stood then, so a 2023-09-24 pin is wrong here: the patch's pre-image for
    # src/fcdir.c is blob 2e4fdc6, which fontconfig carries from c2290882
    # (2024-02-10) until 2024-11-01. Verified locally at c2290882: both
    # fontconfig patches apply cleanly, no 3-way needed.
    #
    # GIT_REMOTE_NAME removed - see xxhash.cmake; left set it resets to @{u}
    # every build and undoes the pin.
    GIT_TAG c22908828fb2dbfdf38733d119adc1cf5fe00173
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
