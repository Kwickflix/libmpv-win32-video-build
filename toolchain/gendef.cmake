ExternalProject_Add(gendef
    DEPENDS
        mingw-w64
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    SOURCE_DIR ${MINGW_SRC}
    CONFIGURE_COMMAND ${EXEC} CONF=1 <SOURCE_DIR>/mingw-w64-tools/gendef/configure
        --prefix=${CMAKE_INSTALL_PREFIX}
        # Kwick (W-083): gendef is a HOST build tool and its own Makefile.am
        # passes -Werror. Built by the container's 2026 host gcc (16.2.1), the
        # pinned 2023 mingw-w64 source trips -Wdiscarded-qualifiers on
        # strrchr/strchr and every warning becomes an error. CFLAGS lands after
        # AM_CFLAGS on the command line, so -Wno-error wins. This affects only a
        # build-time utility, never the shipped DLL.
        CFLAGS=-Wno-error
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install-strip
    LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

cleanup(gendef install)
