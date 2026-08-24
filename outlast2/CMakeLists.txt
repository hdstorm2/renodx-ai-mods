include(${CMAKE_CURRENT_LIST_DIR}/../cmake/shader-compiler.cmake)

set(addon_name "outlast2-hdr")
set(addon_folder "outlast2")

add_shader(
  shader_0x332766C0_dx11
  "${CMAKE_CURRENT_SOURCE_DIR}/0x332766C0.ps_5_0.hlsl"
  "0x332766C0"
  "ps_5_0"
  "dx11"
)

add_library(renodx_${addon_name} MODULE
  addon.cpp
  ${shader_0x332766C0_dx11}
)

target_include_directories(renodx_${addon_name} PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${RENODX_INCLUDE_DIR}
)

target_compile_definitions(renodx_${addon_name} PRIVATE
  NOMINMAX
  WIN32_LEAN_AND_MEAN
)

set_target_properties(renodx_${addon_name} PROPERTIES
  PREFIX ""
  SUFFIX ".addon64"
  OUTPUT_NAME "renodx-${addon_name}"
)

target_link_libraries(renodx_${addon_name} PRIVATE
  version
  d3dcompiler
)

install(TARGETS renodx_${addon_name}
  LIBRARY DESTINATION .
)

install(FILES renodx.json
  DESTINATION .
  RENAME renodx-${addon_name}.json
)
