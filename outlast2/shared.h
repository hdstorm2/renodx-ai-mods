#pragma once

struct ShaderInjectData {
  // Tone mapping
  float tone_map_type = 1.f;  // 0 = Vanilla, 1 = RenoDX
  float peak_white_nits = 1000.f;
  float diffuse_white_nits = 203.f;
  float graphics_white_nits = 203.f;
  float gamma_correction = 1.f;  // 0 = Off, 1 = 2.2 EOTF
};
