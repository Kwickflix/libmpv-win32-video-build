ExternalProject_Add(spirv-tools
    GIT_REPOSITORY https://github.com/KhronosGroup/SPIRV-Tools.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    # Kwick (W-083): PIN to 2023-09-24, part of the shaderc version set.
    GIT_TAG ee7598d49798e7bf34fabe55b5a438a381d450c8
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1
)

force_rebuild_git(spirv-tools)
cleanup(spirv-tools install)
