ExternalProject_Add(angle-headers
    GIT_REPOSITORY https://github.com/google/angle.git
    SOURCE_DIR ${SOURCE_LOCATION}
    # Kwick (W-083): PIN to 9fc3baf5 (2023-09-22), contemporaneous with the mpv
    # commit this build is pinned to. Tracking ANGLE's `main` put 2026 EGL
    # headers under 2023 mpv, and Google has since removed the D3D9 backend, so
    # mpv's ANGLE context no longer compiles:
    #   video/out/opengl/context_angle.c:336: error: use of undeclared
    #   identifier 'EGL_PLATFORM_ANGLE_TYPE_D3D9_ANGLE'
    # Checked directly: eglext_angle.h defines that constant at 9fc3baf5 and
    # does not on main today. Disabling ANGLE is not an option - the DLL we
    # ship is built -Degl-angle=enabled.
    #
    # GIT_REMOTE_NAME removed with the pin. force_rebuild_git() treats an unset
    # GIT_REMOTE_NAME as "a commit hash is pinned"; left set it resets the
    # checkout to @{u} (origin/main) on every build and silently undoes the pin
    # - the xxhash trap.
    GIT_TAG 9fc3baf5a19f86276c1b5911fab70a576e0b0fa3
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set include/EGL include/KHR"
    GIT_SUBMODULES ""
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include/EGL ${MINGW_INSTALL_PREFIX}/include/EGL
            COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include/KHR ${MINGW_INSTALL_PREFIX}/include/KHR
    LOG_DOWNLOAD 1 LOG_UPDATE 1
)

force_rebuild_git(angle-headers)
cleanup(angle-headers install)
