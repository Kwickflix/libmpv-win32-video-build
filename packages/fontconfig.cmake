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
    # Kwick (W-083): restore the tree, THEN apply, as two separate COMMANDs.
    # A package whose build fails anywhere AFTER its patch step is left with the
    # patch in its working tree - nothing puts it back, because the restore
    # lives in `postremovebuild`, which only runs after a successful install.
    # The next run then re-applies a patch that is already in and dies with
    #   error: patch failed: <file>:<line>
    #   error: <file>: patch does not apply
    # which is what happened to ffmpeg. `git checkout -f -- .` is a no-op on a
    # clean tree and makes the patch step start from the same place every time.
    #
    # It has to be a second COMMAND, not `&& git apply` on one line: CMake
    # renders the step as a shell line and only prefixes the FIRST segment with
    # ${EXEC}, so the `git apply` half lost the wrapper - and with it the
    # `eval` that expands the *.patch glob:
    #   error: can't open patch '.../fontconfig-*.patch': No such file or
    #   directory
    PATCH_COMMAND ${EXEC} git checkout -f -- .
    COMMAND ${EXEC} git apply ${CMAKE_CURRENT_SOURCE_DIR}/fontconfig-*.patch
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
