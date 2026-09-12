#!/usr/bin/env python3
# ==============================================================================
# Project: Apex HORIZON IVI - Raspberry Pi 5 Digital Cockpit Head Unit
# Developer: Sk Rehan Ahamed
# File: generate_release_notes.py
# ==============================================================================

import sys

def generate(tag):
    body = f"""## Apex HORIZON IVI - Raspberry Pi 5 Platform Release {tag}

### Key Subsystems & Features in {tag}

#### 1. Native Raspberry Pi 5 Hardware Acceleration (DRM/KMS EGLFS)
- **Direct VideoCore VII Rendering**: Runs at a deterministic 60 FPS directly via Linux DRM/KMS Kernel Mode Setting, completely bypassing X11/Wayland display server overhead.
- **Automotive Appliance Mode**: Custom systemd unit and LightDM configuration for direct headless automotive boot into fullscreen IVI head unit in under 3 seconds.
- **Dynamic Resolution Switching**: Integrated `pi-resolution` tool to switch live between 1080p, 720p, and 600p automotive aspect ratios.

#### 2. Bluetooth Media & PipeWire Audio Pipeline
- **PipeWire A2DP Sink**: Low-latency wireless Bluetooth audio streaming directly to the Raspberry Pi 5 HDMI or I2S DAC audio outputs.
- **Centered Media Card**: Modernized Bluetooth audio card with centered high-contrast typography (`font.pixelSize: 44` / `25`).
- **BlueZ 5 Media Controller**: Native track control (Play, Pause, Skip Next, Skip Previous) with song title and artist synchronization.

#### 3. Integrated Telephony & PBAP Phonebook Sync
- **OpenOBEX Phonebook Engine**: Automatic sync of contacts (`telecom/pb.vcf`) from paired phones into local SQLite database.
- **Automotive In-Call Cockpit**: Floating / Fullscreen active call manager with mic mute, private mode, and call-end controls.
- **Deterministic Audio Priority**: System-level audio ducking automatically silences radio and music during incoming or active phone calls.

#### 4. Live Broadcast Radio & Physical Button Emulation
- **Preconfigured Radio Streams**: Live Indian FM stations with fast stream startup and perceptual volume loudness curve.
- **Hardware Button / CAN-Bus Emulation**: Keybindings and GPIO emulator service for steering wheel controls (Volume Up/Down, Mute, Next/Prev Track, Home, Back).

---

### Release Package Assets
| Artifact | Description |
| :--- | :--- |
| **`apex-ivi-rpi5-configs.tar.gz`** | Complete Raspberry Pi 5 DRM/KMS configuration, PipeWire routing scripts, and systemd service units. |
| **`apex-ivi-source-{tag}.zip`** | Full standalone source code bundle with Qt 6 C++ engine and QML cockpit assets. |

See [README.md](https://github.com/skrehanahamed/apex_IVI_midEnd_rasberryPi5#readme) for quick deployment and hardware setup.

<sub>Engineered by **Sk Rehan Ahamed** | Automotive Digital Cockpit Systems</sub>
"""

    with open('release_body.md', 'w', encoding='utf-8') as out:
        out.write(body)
    print(f"Generated release_body.md for {tag}")

if __name__ == '__main__':
    tag_arg = sys.argv[1] if len(sys.argv) > 1 else 'v1.1.0'
    generate(tag_arg)
