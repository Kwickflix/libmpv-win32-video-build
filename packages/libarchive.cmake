ExternalProject_Add(libarchive
    DEPENDS
        bzip2
        expat
        lzo
        xz
        zlib
        libxml2
    GIT_REPOSITORY https://github.com/libarchive/libarchive.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    # Kwick (W-083): PIN to 01f3e9fb (2026-09-08 00:58Z), the mainline commit
    # immediately before merge c4cfba67, which landed upstream commit e1dcb29
    # "Windows: Use bcrypt even if CNG is disabled" at 01:26Z the same morning.
    # That commit is an upstream regression for exactly our configuration.
    # It deleted this from CMakeLists.txt:
    #     ELSE(ENABLE_CNG)
    #       UNSET(HAVE_BCRYPT_H CACHE)
    # so with -DENABLE_CNG=OFF (set below, and upstream's own default here)
    # HAVE_BCRYPT_H is now defined while ARCHIVE_CRYPTO_*_WIN is not. The two
    # guards then disagree: archive_digest.c compiles its win_crypto_* bodies
    # on `#if defined(HAVE_BCRYPT_H)` alone, while archive_digest_private.h
    # only includes <bcrypt.h> and declares Digest_CTX when an
    # ARCHIVE_CRYPTO_*_WIN is set. 15 errors, starting
    #     archive_digest.c:75: unknown type name 'Digest_CTX'
    #     archive_digest.c:81: call to undeclared function 'BCryptHashData'
    # Turning ENABLE_CNG ON would also make the guards agree, but it changes
    # what goes into the DLL we ship (Zip AES via CNG, plus a bcrypt link)
    # away from the stock build, so pin instead. libarchive is unpatched, so
    # the pin carries no patch pre-image concern; CMake floor at 01f3e9fb is
    # 3.17, fine under CMake 4.4.3. Revisit when upstream fixes the guard.
    GIT_TAG 01f3e9fb610f0af45527436af721693d40def767
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} CONF=1 cmake -H<SOURCE_DIR> -B<BINARY_DIR>
        -G Ninja
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DCMAKE_INSTALL_PREFIX=${MINGW_INSTALL_PREFIX}
        -DCMAKE_FIND_ROOT_PATH=${MINGW_INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS=OFF
        -DENABLE_ZLIB=ON
        # Kwick (W-083): OFF, to match the DLL Kwick Player ships. That binary
        # contains libarchive's "ZSTD codec is unsupported" string - the message
        # libarchive compiles in when zstd support is absent - and only two
        # zstd-ish strings in 29 MB, where a linked libzstd would leave
        # hundreds. So the shipped engine has no zstd either.
        # It also removes a blocker: zstd 1.6.0 fails to configure under CMake
        # 4.4.3 with "check_compiler_flag: CXX: needs to be enabled before use"
        # (AddZstdCompilationFlags.cmake calls CHECK_CXX_COMPILER_FLAG while the
        # project declares C only). Pinning is not a way out either - zstd
        # v1.5.5 and older declare cmake_minimum_required 2.8.12, which CMake 4
        # rejects outright. If zstd is ever needed, v1.5.6 is the usable one.
        -DENABLE_ZSTD=OFF
        -DENABLE_BZip2=ON
        -DENABLE_ICONV=ON
        -DENABLE_LIBXML2=ON
        -DENABLE_EXPAT=ON
        -DENABLE_LZO=ON
        -DENABLE_LZMA=ON
        -DENABLE_CPIO=OFF
        -DENABLE_CNG=OFF
        -DENABLE_CAT=OFF
        -DENABLE_TAR=OFF
        -DENABLE_WERROR=OFF
        -DBUILD_TESTING=OFF
        -DENABLE_TEST=OFF
        -DWINDOWS_VERSION=WIN10
    BUILD_COMMAND ${EXEC} ninja -C <BINARY_DIR>
    INSTALL_COMMAND ${EXEC} ninja -C <BINARY_DIR> install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(libarchive)
cleanup(libarchive install)
