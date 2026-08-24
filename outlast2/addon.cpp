/*
 * Copyright (C) 2025 hdstorm2
 * SPDX-License-Identifier: MIT
 */

#define ImTextureID ImU64
#define DEBUG_LEVEL_0

#include <deps/imgui/imgui.h>
#include <include/reshade.hpp>

#include <embed/shaders.h>

#include "../../mods/shader.hpp"
#include "../../mods/swapchain.hpp"
#include "../../templates/settings.hpp"
#include "../../utils/settings.hpp"
#include "./shared.h"

namespace {

renodx::mods::shader::CustomShaders custom_shaders = {
    __ALL_CUSTOM_SHADERS,
};

ShaderInjectData shader_injection;

renodx::utils::settings::Settings settings = renodx::templates::settings::CreateDefaultSettings({
    {"ToneMapType", &shader_injection.tone_map_type},
    {"ToneMapPeakNits", &shader_injection.peak_white_nits},
    {"ToneMapGameNits", &shader_injection.diffuse_white_nits},
    {"ToneMapUINits", &shader_injection.graphics_white_nits},
    {"ToneMapGammaCorrection", &shader_injection.gamma_correction},
    {"ToneMapScaling", nullptr},  // Per-channel vs luminance
    {"ToneMapHueCorrection", &shader_injection.tone_map_hue_correction},
    {"ToneMapHueShift", &shader_injection.tone_map_hue_shift},
    {"ColorGradeExposure", &shader_injection.tone_map_exposure},
    {"ColorGradeHighlights", &shader_injection.tone_map_highlights},
    {"ColorGradeShadows", &shader_injection.tone_map_shadows},
    {"ColorGradeContrast", &shader_injection.tone_map_contrast},
    {"ColorGradeSaturation", &shader_injection.tone_map_saturation},
    {"ColorGradeHighlightSaturation", &shader_injection.tone_map_highlight_saturation},
    {"ColorGradeBlowout", &shader_injection.tone_map_blowout},
    {"ColorGradeFlare", &shader_injection.tone_map_flare},
});

void OnPresetOff() {
  renodx::utils::settings::UpdateSettings({
      {"ToneMapType", 0.f},
      {"ToneMapPeakNits", 203.f},
      {"ToneMapGameNits", 203.f},
      {"ToneMapUINits", 203.f},
      {"ToneMapGammaCorrection", 0.f},
      {"ToneMapHueCorrection", 100.f},
      {"ToneMapHueShift", 50.f},
      {"ColorGradeExposure", 1.f},
      {"ColorGradeHighlights", 50.f},
      {"ColorGradeShadows", 50.f},
      {"ColorGradeContrast", 50.f},
      {"ColorGradeSaturation", 50.f},
      {"ColorGradeHighlightSaturation", 50.f},
      {"ColorGradeBlowout", 0.f},
      {"ColorGradeFlare", 0.f},
  });
}

bool initialized = false;

}  // namespace

extern "C" __declspec(dllexport) constexpr const char* NAME = "RenoDX";
extern "C" __declspec(dllexport) constexpr const char* DESCRIPTION = "RenoDX for Outlast 2 (HDR)";

BOOL APIENTRY DllMain(HMODULE h_module, DWORD fdw_reason, LPVOID lpv_reserved) {
  switch (fdw_reason) {
    case DLL_PROCESS_ATTACH:
      if (!reshade::register_addon(h_module)) return FALSE;

      if (!initialized) {
        renodx::mods::shader::force_pipeline_cloning = true;
        renodx::mods::shader::expected_constant_buffer_space = 50;
        renodx::mods::shader::expected_constant_buffer_index = 13;
        renodx::mods::shader::allow_multiple_push_constants = true;

        renodx::mods::swapchain::expected_constant_buffer_index = 13;
        renodx::mods::swapchain::expected_constant_buffer_space = 50;
        renodx::mods::swapchain::use_resource_cloning = true;
        renodx::mods::swapchain::SetUseHDR10(true);
        
        renodx::mods::swapchain::swap_chain_proxy_shaders = {
            {
                reshade::api::device_api::d3d11,
                {
                    .vertex_shader = __swap_chain_proxy_vertex_shader_dx11,
                    .pixel_shader = __swap_chain_proxy_pixel_shader_dx11,
                },
            },
        };

        renodx::mods::swapchain::swap_chain_upgrade_targets.push_back({
            .old_format = reshade::api::format::r8g8b8a8_unorm,
            .new_format = reshade::api::format::r16g16b16a16_float,
            .use_resource_view_cloning = true,
        });

        renodx::mods::swapchain::swap_chain_upgrade_targets.push_back({
            .old_format = reshade::api::format::r8g8b8a8_typeless,
            .new_format = reshade::api::format::r16g16b16a16_float,
            .use_resource_view_cloning = true,
        });

        renodx::mods::swapchain::force_screen_tearing = false;
        renodx::mods::swapchain::swapchain_proxy_revert_state = true;

        initialized = true;
      }

      break;
    case DLL_PROCESS_DETACH:
      reshade::unregister_addon(h_module);
      break;
  }

  renodx::utils::settings::Use(fdw_reason, &settings, &OnPresetOff);
  renodx::mods::swapchain::Use(fdw_reason, &shader_injection);
  renodx::mods::shader::Use(fdw_reason, custom_shaders, &shader_injection);

  return TRUE;
}
