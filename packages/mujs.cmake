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
    PATCH_COMMAND ${EXEC} git am --3way ${CMAKE_CURRENT_SOURCE_DIR}/mujs-*.patch
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
