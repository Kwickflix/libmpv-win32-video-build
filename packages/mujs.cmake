set(flag
"CFLAGS='-UHAVE_READLINE' LIBREADLINE=''
CC=${TARGET_ARCH}-gcc
AR=${TARGET_ARCH}-ar
RANLIB=${TARGET_ARCH}-ranlib
OUT=<BINARY_DIR>
prefix=${MINGW_INSTALL_PREFIX}
host=mingw")

ExternalProject_Add(mujs
    GIT_REPOSITORY https://github.com/ccxvii/mujs.git
    # Kwick (W-083): PIN to 2023-08-10. Patched package with no GIT_TAG at all,
    # so it tracked the default branch. mpv is built -Djavascript=enabled, so
    # MuJS is statically linked into the DLL we ship (ISC licence - see
    # THIRD_PARTY_LICENSES.md section 1a).
    GIT_TAG 9f5bc0ff812c2ad550396d3506e5f1328bbcce70
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
    PATCH_COMMAND ${EXEC} git apply ${CMAKE_CURRENT_SOURCE_DIR}/mujs-*.patch
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${MAKE} -C <SOURCE_DIR> ${flag}
    INSTALL_COMMAND ${MAKE} -C <SOURCE_DIR> ${flag} install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

ExternalProject_Add_Step(mujs delete-dir
    DEPENDEES install
    COMMAND ${CMAKE_COMMAND} -E rm -rf <SOURCE_DIR>/build
    COMMENT "Delete build dir"
)

force_rebuild_git(mujs)
cleanup(mujs delete-dir)
