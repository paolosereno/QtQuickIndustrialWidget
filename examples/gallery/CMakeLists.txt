# SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
# SPDX-License-Identifier: MIT

qt_add_executable(gallery
    main.cpp
)

qt_add_qml_module(gallery
    URI GalleryApp
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    QML_FILES
        Main.qml
)

target_link_libraries(gallery
    PRIVATE
        QtQuickIndustrialWidgets
        QtQuickIndustrialWidgetsplugin
        QtQuickIndustrialWidgetsplugin_init
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
        Qt6::Qml
)

qt_import_qml_plugins(gallery)
