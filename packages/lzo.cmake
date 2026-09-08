ExternalProject_Add(lzo
    # Kwick (W-083): fossies.org now answers HTTP 410 Gone for this file.
    # Switched to the canonical upstream at oberhumer.com, which serves the
    # identical tarball - its SHA1 was checked against the URL_HASH below
    # before making this change, and matches.
    URL "https://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz"
    URL_HASH SHA1=4924676a9bae5db58ef129dc1cebce3baa3c4b5d
    DOWNLOAD_DIR ${SOURCE_LOCATION}
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} CONF=1 <SOURCE_DIR>/configure
        --host=${TARGET_ARCH}
        --prefix=${MINGW_INSTALL_PREFIX}
        --disable-shared
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

cleanup(lzo install)
