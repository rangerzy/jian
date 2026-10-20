cmake_minimum_required(VERSION 3.24)

project(jian VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.12 REQUIRED COMPONENTS Quick)
qt_standard_project_setup(REQUIRES 6.12)

qt_add_executable(jian
    WIN32 MACOSX_BUNDLE
    src/main.cpp
)

qt_add_qml_module(jian
    URI Jian
    VERSION 1.0
    QML_FILES qml/Main.qml
)

target_link_libraries(jian PRIVATE Qt6::Quick)
target_compile_definitions(jian PRIVATE JIAN_VERSION="${PROJECT_VERSION}")

set_target_properties(jian PROPERTIES
    MACOSX_BUNDLE_BUNDLE_NAME "jian"
    MACOSX_BUNDLE_GUI_IDENTIFIER "io.github.rangerzy.jian"
    MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
)

file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/version.txt" CONTENT "${PROJECT_VERSION}\n")

include(GNUInstallDirs)
install(TARGETS jian
    BUNDLE DESTINATION .
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
)

if(APPLE)
    qt_generate_deploy_qml_app_script(
        TARGET jian
        OUTPUT_SCRIPT jian_deploy_script
        DEPLOY_TOOL_OPTIONS -no-codesign -verbose=1
    )
    install(SCRIPT "${jian_deploy_script}")
endif()

if(UNIX AND NOT APPLE)
    install(FILES packaging/linux/io.github.rangerzy.jian.desktop
        DESTINATION "${CMAKE_INSTALL_DATADIR}/applications")
    install(FILES packaging/linux/io.github.rangerzy.jian.svg
        DESTINATION "${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps")
endif()

include(CTest)
if(BUILD_TESTING)
    add_test(NAME jian_startup COMMAND jian --smoke-test)
    set_tests_properties(jian_startup PROPERTIES
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software"
        TIMEOUT 15
    )
endif()
