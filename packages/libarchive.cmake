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
        # Kwick (W-083): ON. It was OFF (upstream media-kit's setting), and OFF
        # does not build on Windows at either side of the merge that landed
        # upstream commit e1dcb29 "Windows: Use bcrypt even if CNG is disabled"
        # on 2026-09-08 01:26Z:
        #   before it, archive_random.c calls BCryptGenRandom while bcrypt is
        #   not in ADDITIONAL_LIBS, so bsdunzip.exe fails to link with
        #     ld.lld: error: undefined symbol: BCryptGenRandom
        #   after it, HAVE_BCRYPT_H is defined while ARCHIVE_CRYPTO_*_WIN is
        #   not, so archive_digest.c compiles its win_crypto_* bodies against a
        #   header that declares neither <bcrypt.h> nor Digest_CTX:
        #     archive_digest.c:75: unknown type name 'Digest_CTX'
        #
        # ON is also what the DLL Kwick Player actually ships was built with,
        # read straight out of its import table: it imports twelve symbols from
        # bcrypt.dll, including BCryptDeriveKeyPBKDF2 and
        # BCryptGenerateSymmetricKey (libarchive's archive_cryptor.c, Zip AES),
        # BCryptCreateHash / BCryptHashData / BCryptFinishHash
        # (archive_digest.c) and BCryptGenRandom (archive_random.c). That is
        # libarchive's CNG feature set exactly, and nothing else in this build
        # uses CNG PBKDF2. So OFF never described the engine we ship - the same
        # story as vulkan and libplacebo, where the recipe as written did not
        # produce our binary either. ON restores parity, makes both guards
        # agree at any libarchive commit, and puts bcrypt on the link line for
        # everything downstream that pulls in libarchive.a.
        -DENABLE_CNG=ON
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
