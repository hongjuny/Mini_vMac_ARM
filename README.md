# Mini vMac for Apple Silicon

Native ARM64 build of Mini vMac (Macintosh Plus emulator) optimized for modern macOS.

![Mini vMac running on Apple Silicon Mac](screenshots/minivmac-apple-silicon.png)

## Features

- **Native Apple Silicon Support**: Compiled for ARM64 architecture (M1/M2/M3)
- **Retina Display Support**: Proper high-DPI rendering
- **Classic Mac Emulation**: Emulates Macintosh Plus with 68000 processor

## Quick Start

### Building from Source

```bash
# 1. Build the setup tool
gcc setup/tool.c -o setup_tool

# 2. Generate build configuration
./setup_tool -t mc64 > setup.sh
chmod +x setup.sh
./setup.sh

# 3. Build Mini vMac
make
```

The application will be created at `minivmac.app`.

### Running Mini vMac

1. Obtain a Macintosh Plus ROM file (typically named `vMac.ROM`)
2. Place the ROM file in the same directory as minivmac.app
3. Launch Mini vMac
4. Drag and drop `.dsk` disk images onto the window to mount them

## Changelog

### 2024-11-04
- **Fixed audio output issues** ([#2](https://github.com/hongjuny/Mini_vMac_ARM/commit/XXXXXX))
  - Updated deprecated Component Manager API to modern AudioComponent API
  - Replaced `FindNextComponent` with `AudioComponentFindNext`
  - Replaced `OpenAComponent` with `AudioComponentInstanceNew`
  - Replaced `CloseComponent` with `AudioComponentInstanceDispose`
  - Result: Audio now works correctly on modern macOS including with Bluetooth devices

- **Fixed Retina display scaling** ([#1](https://github.com/hongjuny/Mini_vMac_ARM/commit/XXXXXX))
  - Modified `src/OSGLUCCO.m` to properly handle high-DPI displays
  - Use `convertRectToBacking` for correct framebuffer dimensions
  - Apply `backingScaleFactor` to `glPixelZoom` for proper pixel scaling
  - Scale `glRasterPos2i` coordinates to match physical framebuffer
  - Result: Full window utilization on Retina displays instead of quarter-screen rendering

### 2024-11-03
- **Initial ARM64 port**
  - Successfully compiled for Apple Silicon
  - Native performance on M1/M2/M3 processors
  - Maintained compatibility with existing disk images

## Known Issues

- OpenGL deprecation warnings (functional but will need Metal port in future)

## Technical Notes

### Retina Display Support
The main challenge was that NSView returns logical coordinates while OpenGL needs physical pixel coordinates. The fix involves:
1. Getting the backing scale factor from the window
2. Applying this scale to both the viewport setup and pixel drawing operations
3. Ensuring coordinate transformations are consistent throughout the rendering pipeline

### Build Configuration
- Target: `mc64` (macOS 64-bit)
- Compiler: Xcode Command Line Tools GCC/Clang
- Frameworks: AppKit, AudioUnit, OpenGL

## Contributing

Issues and pull requests are welcome. Please test on both Retina and non-Retina displays when making rendering changes.

## Original Project

Mini vMac is created by Paul C. Pratt. Visit [gryphel.com/c/minivmac/](https://www.gryphel.com/c/minivmac/) for the original project.

## License

GNU General Public License version 2. See README.txt for full license text.