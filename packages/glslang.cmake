ExternalProject_Add(glslang
    GIT_REPOSITORY https://github.com/KhronosGroup/glslang.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    # Kwick (W-083): PIN to 2023-09-24, part of the shaderc version set.
    GIT_TAG 2bfacdac91d5d9ba6bab7b4da52eb79c2300cd45
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1
)

force_rebuild_git(glslang)
cleanup(glslang install)
