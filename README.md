# RenoDX AI Mods

A collection of RenoDX HDR mods for games, created with AI assistance.

## Mods Included


## Building

### Requirements
- CMake 3.27+
- Visual Studio 2022 (C++20)
- Windows SDK 10
- ReShade SDK
- DirectX Shader Compiler (DXC)

### Build Steps

```bash
# Clone the repository
git clone https://github.com/hdstorm2/renodx-ai-mods
cd renodx-ai-mods

# Create build directory
mkdir build
cd build

# Configure with CMake
cmake .. -G "Visual Studio 17 2022" -A x64

# Build
cmake --build . --config Release

# Built addons will be in build/Release/
```

### Standalone Mod Build

To build just one mod:

```bash
cmake --build . --config Release --target renodx_outlast2_hdr
```

## Installation

1. Download the `.addon64` file
2. Place it in your game's installation directory
3. Ensure `ReShade64.dll` or `dxgi.dll` is also in the same folder
4. Launch the game

## Usage

- In-game: Press `Home` to open ReShade overlay
- Adjust settings under the mod's section
- Settings persist between sessions

## Development

Each mod folder contains:
- `addon.cpp` - ReShade addon entry point
- `shared.h` - Shader injection data structures
- `renodx.json` - Metadata and deployment info
- `*.hlsl` - Modified game shaders
- `CMakeLists.txt` - Build configuration
- `README.md` - Mod-specific documentation

## License

MIT

## Credits

- RenoDX framework by clshortfuse (https://github.com/clshortfuse/renodx)
- Mods created by hdstorm2
- AI-assisted development using GitHub Copilot

## Support

For issues, suggestions, or contributions:
- GitHub: https://github.com/hdstorm2/renodx-ai-mods
- Original RenoDX: https://github.com/clshortfuse/renodx
