#!/usr/bin/env bash
set -e

PI_IP="192.168.1.217"
DEPLOY_DIR="/Users/reno/.gemini/antigravity-ide/scratch/rpi5-yocto-qt-env/deploy"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "⚡ [1/4] Building with CMake/Ninja cross-compiler..."
docker run --rm \
  -v /Users/reno/.gemini/antigravity-ide/scratch/rpi5-yocto-qt-env:/workspace \
  -v yocto-tmp:/workspace/build/tmp \
  rpi5-yocto-scarthgap-builder bash -c "
    export PATH=/workspace/build/tmp/work/cortexa76-poky-linux/apex-ivi/1.0/recipe-sysroot-native/usr/bin:/workspace/build/tmp/work/cortexa76-poky-linux/apex-ivi/1.0/recipe-sysroot-native/usr/bin/aarch64-poky-linux:\$PATH && \
    cp -rf /workspace/sources/Apex_MidEnd_IVI/src/* /workspace/build/tmp/work/cortexa76-poky-linux/apex-ivi/1.0/workspace/sources/Apex_MidEnd_IVI/src/ 2>/dev/null || true && \
    cp -rf /workspace/sources/aasdk/* /workspace/build/tmp/work/cortexa76-poky-linux/apex-ivi/1.0/workspace/sources/aasdk/ 2>/dev/null || true && \
    cp -rf /workspace/sources/Apex_MidEnd_IVI/qml/* /workspace/build/tmp/work/cortexa76-poky-linux/apex-ivi/1.0/workspace/sources/Apex_MidEnd_IVI/qml/ 2>/dev/null || true && \
    cp -rf /workspace/sources/Apex_MidEnd_IVI/assets/* /workspace/build/tmp/work/cortexa76-poky-linux/apex-ivi/1.0/workspace/sources/Apex_MidEnd_IVI/assets/ 2>/dev/null || true && \
    cp -f /workspace/sources/Apex_MidEnd_IVI/resources.qrc /workspace/build/tmp/work/cortexa76-poky-linux/apex-ivi/1.0/workspace/sources/Apex_MidEnd_IVI/resources.qrc 2>/dev/null || true && \
    cp -f /workspace/sources/Apex_MidEnd_IVI/CMakeLists.txt /workspace/build/tmp/work/cortexa76-poky-linux/apex-ivi/1.0/workspace/sources/Apex_MidEnd_IVI/CMakeLists.txt 2>/dev/null || true && \
    ninja -C /workspace/build/tmp/work/cortexa76-poky-linux/apex-ivi/1.0/build && \
    mkdir -p /workspace/deploy && \
    /workspace/build/tmp/work/cortexa76-poky-linux/apex-ivi/1.0/recipe-sysroot-native/usr/bin/aarch64-poky-linux/aarch64-poky-linux-strip -s /workspace/build/tmp/work/cortexa76-poky-linux/apex-ivi/1.0/build/ApexIVI -o /workspace/deploy/ApexIVI
  "

echo "📦 [2/4] Pushing PipeWire / WirePlumber audio configs..."
scp -O -o BatchMode=yes -o ConnectTimeout=20 "${SCRIPT_DIR}/10-audio-stability.conf" "root@${PI_IP}:/etc/pipewire/pipewire.conf.d/10-audio-stability.conf"
scp -O -o BatchMode=yes -o ConnectTimeout=20 "${SCRIPT_DIR}/20-ivi-hdmi.conf"      "root@${PI_IP}:/etc/pipewire/pipewire.conf.d/20-ivi-hdmi.conf"
scp -O -o BatchMode=yes -o ConnectTimeout=20 "${SCRIPT_DIR}/10-bluez-ofono.conf"   "root@${PI_IP}:/etc/wireplumber/wireplumber.conf.d/10-bluez-ofono.conf"
# Restart audio stack so the new HDMI period-num and quantum take effect.
ssh "root@${PI_IP}" "rm -f /etc/wireplumber/wireplumber.conf.d/20-bluez-ofono.conf && systemctl daemon-reload && systemctl restart pipewire wireplumber && sleep 1 && systemctl is-active pipewire wireplumber"

echo "📡 [3/4] Pushing app binary and helper scripts..."
scp -O -o BatchMode=yes -o ConnectTimeout=20 "${DEPLOY_DIR}/ApexIVI"                "root@${PI_IP}:/tmp/ApexIVI"
scp -O -o BatchMode=yes -o ConnectTimeout=20 "${SCRIPT_DIR}/apex-fetch-artwork.py"  "root@${PI_IP}:/usr/bin/apex-fetch-artwork.py"
scp -O -o BatchMode=yes -o ConnectTimeout=20 "${SCRIPT_DIR}/apex-usb-reset.py"      "root@${PI_IP}:/usr/bin/apex-usb-reset.py"
ssh "root@${PI_IP}" "chmod +x /usr/bin/apex-fetch-artwork.py /usr/bin/apex-usb-reset.py"

echo "🔄 [4/4] Restarting apex-ivi service on Pi..."
ssh "root@${PI_IP}" "systemctl stop apex-ivi && mv /tmp/ApexIVI /usr/bin/ApexIVI && chmod +x /usr/bin/ApexIVI && /usr/bin/python3 /usr/bin/apex-usb-reset.py || true && systemctl start apex-ivi && systemctl is-active apex-ivi"

echo "✅ Done! Apex IVI updated and running on Raspberry Pi."
