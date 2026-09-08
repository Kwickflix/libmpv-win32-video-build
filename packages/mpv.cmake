ExternalProject_Add(mpv
    DEPENDS
        angle-headers
        ffmpeg
        fribidi
        lcms2
        libarchive
        libass
        libjpeg
        libpng
        uchardet
        mujs
        shaderc
        spirv-cross
    GIT_REPOSITORY https://github.com/mpv-player/mpv.git
    # Kwick (W-083): PIN. This recipe tracked mpv's default branch while
    # pinning FFmpeg to n6.0 (ea3d24bb), so a build today would put 2026 mpv
    # against 2023 FFmpeg - a combination modern mpv does not support, and a
    # far bigger change than the six decoders this fork exists to add.
    # 652a1dd9 is v0.36.0-403-g652a1dd907, the exact commit the DLL Kwick
    # Player ships today was built from (it reports that version string).
    GIT_TAG 652a1dd90711839acdccc08004056d25514ef2d8
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} CONF=1 meson setup <BINARY_DIR> <SOURCE_DIR>
        --prefix=${MINGW_INSTALL_PREFIX}
        --libdir=${MINGW_INSTALL_PREFIX}/lib
        --cross-file=${MESON_CROSS}
        --default-library=shared
        --prefer-static
        -Ddebug=true
        -Db_ndebug=true
        -Doptimization=3
        -Db_lto=true
        ${mpv_lto_mode}
        -Dgpl=false
        -Db_lto=true
        -Db_ndebug=true
        -Dlibmpv=true
        -Dpdf-build=enabled
        -Dlua=disabled
        -Djavascript=enabled
        -Duchardet=enabled
        -Dlcms2=enabled
        -Dopenal=disabled
        -Dspirv-cross=enabled
        # Kwick (W-083): the DLL Kwick Player ships reports, in its own embedded
        # mpv configure string, "-Dvulkan=disabled -Dlibplacebo=disabled". This
        # repo's recipe says enabled, so the recipe alone never produced our
        # DLL - media-kit passed the workflow's "command" input to change flags
        # at build time, and those run logs have expired. Match the shipped
        # binary, which is the record. It also drops the vulkan package, whose
        # cross-compile patch no longer applies to Vulkan-Loader master
        # ("sha1 information is lacking or useless (loader/CMakeLists.txt)").
        -Dvulkan=disabled
        -Dlibplacebo=disabled
        -Degl-angle=enabled
    # Kwick (W-083): -k 0 here too. This is mpv's OWN ninja, nested inside the
    # outer build, so the outer -k 0 does not reach it: mpv stops at its first
    # compile error and one 25-minute run reports one broken file. mpv is the
    # last package, so that is the most expensive place to find things one at a
    # time. Same bargain as the workflow - ninja still exits non-zero.
    BUILD_COMMAND ${EXEC} LTO_JOB=1 ninja -k 0 -C <BINARY_DIR>
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

# Kwick (W-083): copy the optional debug artefacts only if the build actually
# produced them. mpv.com and mpv.pdb are the two files this configuration does
# not always emit: mpv 652a1dd9 built with -Dlibmpv=true links exactly
# libmpv-2.dll and mpv.exe (read out of the run log), and the mingw clang driver
# emits DWARF rather than a PDB. `cmake -E copy` on a missing source fails the
# step, and this step is what populates mpv-dev - the package carrying
# libmpv-2.dll, the only thing Kwick Player needs out of this build.
#
# A script, not a `test -f ... &&` inside the COMMAND: CMake splits a *_COMMAND
# on `&&` and prefixes only the first segment with ${EXEC}, whose `eval $*` is
# what the rest would depend on. Same idiom as rename.sh below.
set(OPTIONAL_COPY ${CMAKE_CURRENT_BINARY_DIR}/mpv-prefix/src/optional_copy.sh)
file(WRITE ${OPTIONAL_COPY}
"#!/bin/bash
# $1 = mpv build dir, $2 = destination
mkdir -p \"$2\"
for f in mpv.pdb mpv.debug; do
    if [ -f \"$1/$f\" ]; then cp -f \"$1/$f\" \"$2/$f\"; echo \"copied $f\"; else echo \"$f not built, skipping\"; fi
done
exit 0")
file(CHMOD ${OPTIONAL_COPY}
PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

ExternalProject_Add_Step(mpv strip-binary
    DEPENDEES build
    ${mpv_add_debuglink}
    COMMAND ${EXEC} ${TARGET_ARCH}-strip -s <BINARY_DIR>/mpv.exe
    COMMAND ${EXEC} ${TARGET_ARCH}-strip -s <BINARY_DIR>/libmpv-2.dll
    COMMENT "Stripping mpv binaries"
)

ExternalProject_Add_Step(mpv copy-binary
    DEPENDEES strip-binary
    COMMAND ${CMAKE_COMMAND} -E copy <BINARY_DIR>/mpv.exe                           ${CMAKE_CURRENT_BINARY_DIR}/mpv-package/mpv.exe
    COMMAND ${CMAKE_COMMAND} -E copy <BINARY_DIR>/mpv.pdf                           ${CMAKE_CURRENT_BINARY_DIR}/mpv-package/doc/manual.pdf
    COMMAND ${CMAKE_COMMAND} -E copy ${MINGW_INSTALL_PREFIX}/etc/fonts/fonts.conf   ${CMAKE_CURRENT_BINARY_DIR}/mpv-package/mpv/fonts.conf
    # Kwick (W-083): best-effort. ${mpv_copy_debug} copies mpv.pdb for the
    # clang toolchain, but nothing in this configuration asks lld for a PDB
    # (no -Wl,--pdb=), so it may not exist - and one missing optional file
    # here fails the whole step, which is what populates mpv-dev.
    COMMAND ${OPTIONAL_COPY} <BINARY_DIR> ${CMAKE_CURRENT_BINARY_DIR}/mpv-debug
    COMMAND ${CMAKE_COMMAND} -E copy <BINARY_DIR>/libmpv-2.dll          ${CMAKE_CURRENT_BINARY_DIR}/mpv-dev/libmpv-2.dll
    COMMAND ${CMAKE_COMMAND} -E copy <BINARY_DIR>/libmpv.dll.a          ${CMAKE_CURRENT_BINARY_DIR}/mpv-dev/libmpv.dll.a
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/libmpv/client.h       ${CMAKE_CURRENT_BINARY_DIR}/mpv-dev/include/mpv/client.h
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/libmpv/stream_cb.h    ${CMAKE_CURRENT_BINARY_DIR}/mpv-dev/include/mpv/stream_cb.h
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/libmpv/render.h       ${CMAKE_CURRENT_BINARY_DIR}/mpv-dev/include/mpv/render.h
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/libmpv/render_gl.h    ${CMAKE_CURRENT_BINARY_DIR}/mpv-dev/include/mpv/render_gl.h
    COMMENT "Copying mpv binaries and manual"
)

set(RENAME ${CMAKE_CURRENT_BINARY_DIR}/mpv-prefix/src/rename.sh)
file(WRITE ${RENAME}
"#!/bin/bash
cd $1
GIT=$(git rev-parse --short=7 HEAD)
mv $2 $2-git-\${GIT}")

ExternalProject_Add_Step(mpv copy-package-dir
    DEPENDEES copy-binary
    COMMAND chmod 755 ${RENAME}
    COMMAND mv ${CMAKE_CURRENT_BINARY_DIR}/mpv-package ${CMAKE_BINARY_DIR}/mpv-${TARGET_CPU}${x86_64_LEVEL}-${BUILDDATE}
    COMMAND ${RENAME} <SOURCE_DIR> ${CMAKE_BINARY_DIR}/mpv-${TARGET_CPU}${x86_64_LEVEL}-${BUILDDATE}

    COMMAND mv ${CMAKE_CURRENT_BINARY_DIR}/mpv-debug ${CMAKE_BINARY_DIR}/mpv-debug-${TARGET_CPU}${x86_64_LEVEL}-${BUILDDATE}
    COMMAND ${RENAME} <SOURCE_DIR> ${CMAKE_BINARY_DIR}/mpv-debug-${TARGET_CPU}${x86_64_LEVEL}-${BUILDDATE}

    COMMAND mv ${CMAKE_CURRENT_BINARY_DIR}/mpv-dev ${CMAKE_BINARY_DIR}/mpv-dev-${TARGET_CPU}${x86_64_LEVEL}-${BUILDDATE}
    COMMAND ${RENAME} <SOURCE_DIR> ${CMAKE_BINARY_DIR}/mpv-dev-${TARGET_CPU}${x86_64_LEVEL}-${BUILDDATE}
    COMMENT "Moving mpv package folder"
    LOG 1
)

force_rebuild_git(mpv)
force_meson_configure(mpv)
cleanup(mpv copy-package-dir)
