ExternalProject_Add(mingw-w64
    GIT_REPOSITORY https://github.com/mingw-w64/mingw-w64.git
    # Kwick (W-083): PIN to 2023-09-23, contemporaneous with the clang 17 this
    # recipe pins. Modern mingw-w64 headers make EXCEPTION_DISPOSITION a real
    # enum, and LLVM 17's libunwind still does `return 4;` from a function
    # returning it, so building llvm-libcxx against today's mingw-w64 fails:
    #   Unwind-seh.cpp:140:14: error: cannot initialize return object of type
    #   'EXCEPTION_DISPOSITION' with an rvalue of type 'int'
    GIT_TAG f9a95f08cd7dc196e0e02d128eab3c09b21a3ab2
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1
)

force_rebuild_git(mingw-w64)
get_property(MINGW_SRC TARGET mingw-w64 PROPERTY _EP_SOURCE_DIR)
