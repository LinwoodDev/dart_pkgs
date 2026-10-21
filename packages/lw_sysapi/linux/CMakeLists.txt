cmake_minimum_required(VERSION 3.10)
project(lw_sysapi LANGUAGES CXX)

set(PLUGIN_NAME "lw_sysapi_plugin")
add_library(${PLUGIN_NAME} SHARED "lw_sysapi_plugin.cc")
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN ON
)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter PkgConfig::GTK)
set(lw_sysapi_bundled_libraries "" PARENT_SCOPE)
