ExternalProject_Add(spirv-cross
    GIT_REPOSITORY https://github.com/KhronosGroup/SPIRV-Cross.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    # Kwick (W-083): PIN to 2023-09-19, contemporaneous with the pinned mpv.
    # This package is patched, and a patched package floating on main is the
    # same trap fontconfig and vulkan fell into. GIT_REMOTE_NAME removed so
    # force_rebuild_git does not reset the pin to @{u}.
    GIT_TAG 43a59b7cff977476167543f5e7e0d51c8d68d745
    UPDATE_COMMAND ""
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
    COMMAND ${EXEC} git apply ${CMAKE_CURRENT_SOURCE_DIR}/spirv-cross-*.patch
    CONFIGURE_COMMAND ${EXEC} CONF=1 cmake -H<SOURCE_DIR> -B<BINARY_DIR>
        -G Ninja
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
        -DCMAKE_INSTALL_PREFIX=${MINGW_INSTALL_PREFIX}
        -DCMAKE_FIND_ROOT_PATH=${MINGW_INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS=OFF
        # Kwick (W-083): the pin above is a 2023 tree, and its CMakeLists.txt
        # declares cmake_minimum_required(VERSION 3.0). CMake 4 removed
        # compatibility below 3.5 and fails with
        #   Compatibility with CMake < 3.5 has been removed from CMake.
        #   Or, add -DCMAKE_POLICY_VERSION_MINIMUM=3.5 to try configuring anyway.
        # This is the cost of pinning old sources, and CMake's own suggested
        # remedy. Same fix as libsoxr.
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
        -DSPIRV_CROSS_SHARED=ON
        -DSPIRV_CROSS_CLI=OFF
        -DSPIRV_CROSS_ENABLE_TESTS=OFF
        -DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS} -D__USE_MINGW_ANSI_STDIO'
    BUILD_COMMAND ${EXEC} ninja -C <BINARY_DIR>
    INSTALL_COMMAND ${EXEC} ninja -C <BINARY_DIR> install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

ExternalProject_Add_Step(spirv-cross symlink
    DEPENDEES install
    COMMAND ${CMAKE_COMMAND} -E create_symlink ${MINGW_INSTALL_PREFIX}/lib/pkgconfig/spirv-cross-c-shared.pc
                                               ${MINGW_INSTALL_PREFIX}/lib/pkgconfig/spirv-cross.pc
)

force_rebuild_git(spirv-cross)
cleanup(spirv-cross install)
