# See template here: 
# https://github.com/microsoft/vcpkg/blob/master/scripts/templates/portfile.in.cmake

message("   [dxc] Running portfile.cmake...")

# ------------------------------------------------
# Download and extract files from source archive
# ------------------------------------------------

if(VCPKG_TARGET_IS_WINDOWS)
    # TODO : Update to v1.7.2212.1 on windows
    set(ARCHIVE_URL "https://github.com/microsoft/DirectXShaderCompiler/releases/download/v1.6.2112/dxc_2021_12_08.zip")
elseif(VCPKG_TARGET_IS_LINUX)
    set(ARCHIVE_URL "https://github.com/microsoft/DirectXShaderCompiler/releases/download/v1.7.2212.1/linux_dxc_2023_03_01.x86_64.tar.gz")
endif()

# Also consider vcpkg_from_github()
# Note : SHA512 can be generated from command prompt, e.g.: "certutil -hashfile "dxc_2021_12_08.zip" SHA512"
vcpkg_download_distfile(
    ARCHIVE # output filename written in this variable
    URLS ARCHIVE_URL
    FILENAME "dxc_2021_12_08.zip"
    SHA512 e9b36e896c1d47b39b648adbecf44da7f8543216fd1df539760f0c591907aea081ea6bfc59eb927073aaa1451110c5dc63003546509ff84c9e4445488df97c27
)

message("   [dxc] vcpkg_extract_source_archive_ex ARCHIVE=${ARCHIVE}")

# ARCHIVE= C:/Dev/vcpkg/downloads/dxc_2021_12_08.zip
# SOURCE_PATH= C:/Dev/vcpkg/buildtrees/dxc/src/2021_12_08-9d706b8711.clean/
vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    NO_REMOVE_ONE_LEVEL # Skip removing the top level directory of the archive.
)

# ------------------------------------------------
# Create CMakeLists.txt for Windows & Linux
# ------------------------------------------------
if(VCPKG_TARGET_IS_WINDOWS)
    message("   [dxc] Writing file: ${SOURCE_PATH}/CMakeLists.txt")
    file(WRITE ${SOURCE_PATH}/CMakeLists.txt [==[
    cmake_minimum_required(VERSION 3.12)
    project(dxc VERSION 0.1.2)
    message("[dxc] Running CMakeLists.txt...")
    include(CMakePackageConfigHelpers)
    include(GNUInstallDirs)
    message("[dxc] Writing file: ${CMAKE_CURRENT_BINARY_DIR}/dxc-config.cmake")
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/dxc-config.cmake [=[
    message("[dxc] Running dxc-config.cmake...")
    get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
    get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
    get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
    if(_IMPORT_PREFIX STREQUAL "/")
    set(_IMPORT_PREFIX "")
    endif()
    add_library(dxc::dxc SHARED IMPORTED)
    set_target_properties(dxc::dxc PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include"
        INTERFACE_LINK_DIRECTORIES "${_IMPORT_PREFIX}/lib"
        IMPORTED_LOCATION ${_IMPORT_PREFIX}/bin/dxcompiler.dll
        IMPORTED_IMPLIB   ${_IMPORT_PREFIX}/lib/dxcompiler.lib
    )
    ]=])
    install(
        FILES
            ${CMAKE_CURRENT_BINARY_DIR}/dxc-config.cmake
        DESTINATION
            ${CMAKE_INSTALL_DATADIR}/dxc)
    install(DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/inc/ TYPE INCLUDE)
    install(DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/bin/x64/ TYPE BIN PATTERN "*.exe" EXCLUDE)
    install(DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/lib/x64/ TYPE LIB)
    ]==])
elseif(VCPKG_TARGET_IS_LINUX)
    set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR})
    file(WRITE ${SOURCE_PATH}/CMakeLists.txt [==[
    cmake_minimum_required(VERSION 3.12)
    project(dxc VERSION 0.1.2)
    include(CMakePackageConfigHelpers)
    include(GNUInstallDirs)
    if("$ENV{VULKAN_SDK}" STREQUAL "")
        message(FATAL_ERROR "On linux, you must have the VulkanSDK installed, (it comes with DXC) download and extract the archive, and source the script within to get the VULKAN_SDK environment variable!")
    endif()
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/dxc-config.cmake [=[
    get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
    get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
    get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
    if(_IMPORT_PREFIX STREQUAL "/")
    set(_IMPORT_PREFIX "")
    endif()
    add_library(dxc::dxc SHARED IMPORTED)
    set_target_properties(dxc::dxc PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES ${_IMPORT_PREFIX}/include
        INTERFACE_LINK_LIBRARIES ${_IMPORT_PREFIX}/lib/libLLVMDxcSupport.a
        INTERFACE_LINK_DIRECTORIES ${_IMPORT_PREFIX}/lib
        IMPORTED_LOCATION ${_IMPORT_PREFIX}/lib/libdxcompiler.so.3.7
        IMPORTED_IMPLIB ${_IMPORT_PREFIX}/lib/libdxclib.a
    )
    ]=])
    install(
        FILES
            ${CMAKE_CURRENT_BINARY_DIR}/dxc-config.cmake
        DESTINATION
            ${CMAKE_INSTALL_DATADIR}/dxc)
    if(EXISTS "$ENV{VULKAN_SDK}/include/dxc")
        install(DIRECTORY $ENV{VULKAN_SDK}/include/dxc TYPE INCLUDE)
    elseif(EXISTS "$ENV{VULKAN_SDK}/../source/DirectXShaderCompiler/include/dxc")
        install(DIRECTORY $ENV{VULKAN_SDK}/../source/DirectXShaderCompiler/include/dxc TYPE INCLUDE FILES_MATCHING PATTERN "*.h")
    else()
        message(FATAL_ERROR "Failed to find the 'include' directory for DXC within the Vulkan SDK. Maybe you have an incompatible version of the SDK installed?")
    endif()
    install(FILES     $ENV{VULKAN_SDK}/lib/libdxcompiler.so.3.7 $ENV{VULKAN_SDK}/lib/libdxclib.a $ENV{VULKAN_SDK}/lib/libLLVMDxcSupport.a TYPE LIB)
    install(FILES     TYPE LIB)
    ]==])
endif()

message("   [dxc] vcpkg_configure_cmake log =${CURRENT_BUILDTREES_DIR}/${LOGFILE_BASE}")
message("   [dxc] SOURCE_PATH=${SOURCE_PATH}")
vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
)

message("   [dxc] vcpkg_install_cmake log =${CURRENT_BUILDTREES_DIR}/${LOGFILE_BASE}")
vcpkg_install_cmake()

# # Moves all .cmake files from /debug/share/dxc/ to /share/dxc/
# # See /docs/maintainers/vcpkg_fixup_cmake_targets.md for more details
# vcpkg_fixup_cmake_targets(CONFIG_PATH cmake TARGET_PATH share/dxc)

message("   [dxc] Skipped removing: ${CURRENT_PACKAGES_DIR}/debug/include")
# file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
message("   [dxc] Skipped removing: ${CURRENT_PACKAGES_DIR}/debug/share")
# file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

if(VCPKG_TARGET_IS_LINUX)
    # We must modify the support/winadapter.h header to actually be able to compile
    file(READ "${CURRENT_PACKAGES_DIR}/include/dxc/Support/WinAdapter.h" WIN_ADAPTER_H)
    string(REGEX REPLACE [=[__uuidof\((.)\)([^ ])]=] [=[__uuidof(decltype(\1{}))\2]=] WIN_ADAPTER_H_FIXED "${WIN_ADAPTER_H}")
    file(WRITE "${CURRENT_PACKAGES_DIR}/include/dxc/Support/WinAdapter.h" "${WIN_ADAPTER_H_FIXED}")
endif()


# ------------------------------------------------
# Create copyright file
# ------------------------------------------------

vcpkg_download_distfile(
    LICENSE_FILE_PATH # output filename written in this variable
    URLS "https://raw.githubusercontent.com/microsoft/DirectXShaderCompiler/v1.7.2212.1/LICENSE.TXT"
    FILENAME "LICENSE.TXT"
    SHA512 7589f152ebc3296dca1c73609a2a23a911b8fc0029731268a6151710014d82005a868c85c8249219f060f64ab1ddecdddff5ed6ea34ff509f63ea3e42bbbf47e
)

message("   [dxc] LICENSE_FILE_PATH=${LICENSE_FILE_PATH}")
vcpkg_install_copyright(FILE_LIST "${LICENSE_FILE_PATH}")
message("   [dxc] output copyright file=${CURRENT_PACKAGES_DIR}/share/${PORT}")