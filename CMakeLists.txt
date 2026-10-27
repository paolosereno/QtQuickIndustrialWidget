# SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
#
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.16)

project(QtQuickIndustrialWidgets
    VERSION 1.0.0
    DESCRIPTION "High-performance Qt Quick / QML Industrial and SCADA Widget Suite"
    HOMEPAGE_URL "https://github.com/paolosereno/QtQuickIndustrialWidget"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Quick Qml)

qt_standard_project_setup()

add_subdirectory(src)

option(BUILD_EXAMPLES "Build gallery showcase application" ON)
if(BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()
