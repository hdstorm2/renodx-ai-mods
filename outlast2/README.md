# Outlast 2 HDR Mod

RenoDX HDR upgrade for Outlast 2 with improved tone mapping and hue preservation.

## Features

- **HDR Support**: Expands SDR output to full HDR range
- **Hue-Preserving Tone Mapping**: Maintains color accuracy during expansion
- **Configurable Peak Brightness**: Adjust peak nits to match your display (48-4000 nits)
- **Game Brightness Control**: Fine-tune game white level (48-500 nits)
- **UI Brightness**: Separate control for UI/HUD elements
- **Gamma Correction**: Optional 2.2 EOTF emulation

## Requirements

- ReShade 5.9.0 or higher
- DirectX 11 (Windows 10/11)
- Steam version of Outlast 2 (AppID: 414700)
- Display capable of HDR (optional but recommended)

## Installation

1. Download the mod files
2. Place `renodx-outlast2-hdr.addon64` in your Outlast 2 installation folder
3. Place `ReShade64.dll` (or `dxgi.dll`) in the same folder if not already present
4. Launch the game

## Settings

Access settings via ReShade overlay (default: Home key):

- **Tone Mapper**: Select tone mapping method (Vanilla/RenoDX)
- **Peak Brightness**: Target peak white in nits (default: 1000)
- **Game Brightness**: 100% white level in nits (default: 203)
- **UI Brightness**: UI/HUD brightness in nits (default: 203)
- **Gamma Correction**: EOTF emulation (Off/2.2)

## Building

Requires:
- CMake 3.27+
- Visual Studio 2022 (C++20)
- ReShade SDK
- DirectX Shader Compiler (DXC)

```bash
mkdir build
cd build
cmake ..
cmake --build . --config Release
```

Output: `renodx-outlast2-hdr.addon64`

## Notes

- Designed for HDR displays using scRGB color space
- Preserves original game art direction
- Recommended: Run in borderless fullscreen for proper HDR
- May require ReShade ini adjustment for optimal results

## Troubleshooting

**No effect in game:**
- Verify ReShade is loaded (check overlay)
- Confirm addon is in game folder
- Check ReShade log for errors

**Colors look wrong:**
- Adjust "Game Brightness" to match original look
- Try different "Tone Mapper" options
- Verify HDR is enabled on your display

## License

MIT

## Credits

Created with RenoDX framework by clshortfuse
HDR implementation by hdstorm2
