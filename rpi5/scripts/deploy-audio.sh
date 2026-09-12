#!/usr/bin/env bash
# ==============================================================================
# Deploy audio infrastructure to the Raspberry Pi (Apex IVI)
# ==============================================================================
set -e

PI_IP="192.168.1.217"
PI_USER="root"
PROJECT_DIR="/root/apex-ivi"
SSH="ssh ${PI_USER}@${PI_IP}"
SCP="scp"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo " Apex IVI Audio Pipeline Deployment"
echo "=========================================="

# 1. Verify connectivity
echo ""
echo "[1/5] Checking Pi connectivity..."
if ! $SSH "echo ok" >/dev/null 2>&1; then
    echo "ERROR: Cannot reach Pi at ${PI_IP}. Check SSH access."
    exit 1
fi
echo "  Pi is reachable."

# 2. Install loopback module
echo ""
echo "[2/5] Configuring ALSA loopback module..."
$SSH "grep -q '^snd-aloop' /etc/modules 2>/dev/null || echo 'snd-aloop' >> /etc/modules"
$SSH "modprobe snd-aloop 2>/dev/null || echo 'Loopback module may already be loaded'"
if $SSH "aplay -l | grep -q Loopback"; then
    echo "  Loopback device detected."
else
    echo "  WARNING: Loopback device not found. Check that snd-aloop is built into the kernel."
fi

# 3. Deploy ALSA configuration
echo ""
echo "[3/5] Deploying ALSA configuration..."
$SCP "${SCRIPT_DIR}/asound.conf" "${PI_USER}@${PI_IP}:${PROJECT_DIR}/asound.conf"
$SSH "cp ${PROJECT_DIR}/asound.conf /etc/asound.conf && echo '  /etc/asound.conf updated'"

# 4. Deploy audio server
echo ""
echo "[4/5] Deploying VNC audio server..."
$SCP "${SCRIPT_DIR}/vnc-audio-server.py" "${PI_USER}@${PI_IP}:${PROJECT_DIR}/vnc-audio-server.py"
$SSH "chmod +x ${PROJECT_DIR}/vnc-audio-server.py && echo '  vnc-audio-server.py deployed'"

# 5. Install audio server as systemd service
echo ""
echo "[5/5] Installing audio server service..."
$SCP "${SCRIPT_DIR}/vnc-audio-server.service" "${PI_USER}@${PI_IP}:/etc/systemd/system/vnc-audio-server.service"
$SSH "systemctl daemon-reload && systemctl enable vnc-audio-server && systemctl restart vnc-audio-server && echo '  Service enabled and started'"

echo ""
echo "=========================================="
echo " Deployment complete!"
echo "=========================================="
echo ""
echo "Verify:"
echo "  ssh ${PI_USER}@${PI_IP} 'systemctl status vnc-audio-server'"
echo ""
echo "Test stream from Mac:"
echo "  ffplay http://${PI_IP}:8000/audio"
echo ""
echo "Then launch VNC:"
echo "  bash ${SCRIPT_DIR}/launch-tigervnc.sh"
