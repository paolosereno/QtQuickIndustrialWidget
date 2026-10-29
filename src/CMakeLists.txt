# SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
# SPDX-License-Identifier: MIT

qt_add_library(QtQuickIndustrialWidgets STATIC)

qt_add_qml_module(QtQuickIndustrialWidgets
    URI "QtQuickIndustrialWidgets"
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    QML_FILES
        QtQuickIndustrialWidgets/LedIndicator.qml
        QtQuickIndustrialWidgets/RadialGauge.qml
        QtQuickIndustrialWidgets/IndustrialKnob.qml
        QtQuickIndustrialWidgets/SevenSegmentDisplay.qml
        QtQuickIndustrialWidgets/LinearGauge.qml
        QtQuickIndustrialWidgets/IndustrialSwitch.qml
        QtQuickIndustrialWidgets/LevelMeter.qml
        QtQuickIndustrialWidgets/NumberFormat.js
)

target_link_libraries(QtQuickIndustrialWidgets
    PUBLIC
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
        Qt6::Qml
)

target_include_directories(QtQuickIndustrialWidgets
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
)
