#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
target="root@192.168.1.217"
python3 -m unittest test_ofono_adapter.py
scp -O -o BatchMode=yes apex-ofono-call.py "$target:/tmp/apex-ofono-call.py"
scp -O -o BatchMode=yes 10-bluez-ofono.conf "$target:/tmp/10-bluez-ofono.conf"
scp -O -o BatchMode=yes 20-ofono-order.conf "$target:/tmp/20-ofono-order.conf"
scp -O -o BatchMode=yes 10-disable-alsa.conf "$target:/tmp/10-disable-alsa.conf"
scp -O -o BatchMode=yes 20-system-audio.conf "$target:/tmp/20-system-audio.conf"
scp -O -o BatchMode=yes apex-pipewire-ofono.conf "$target:/tmp/apex-pipewire-ofono.conf"
scp -O -o BatchMode=yes 20-ivi-hdmi.conf "$target:/tmp/20-ivi-hdmi.conf"
scp -O -o BatchMode=yes 30-pipewire-audio.conf "$target:/tmp/30-pipewire-audio.conf"
ssh -o BatchMode=yes "$target" '
    install -m 755 /tmp/apex-ofono-call.py /usr/bin/apex-hfp-call
    install -d /etc/wireplumber/wireplumber.conf.d
    install -m 644 /tmp/10-bluez-ofono.conf /etc/wireplumber/wireplumber.conf.d/10-bluez-ofono.conf
    install -m 644 /tmp/10-disable-alsa.conf /etc/wireplumber/wireplumber.conf.d/10-disable-alsa.conf
    install -d /etc/systemd/system/pipewire.service.d
    install -m 644 /tmp/20-ofono-order.conf /etc/systemd/system/pipewire.service.d/20-ofono-order.conf
    install -d /etc/systemd/system/wireplumber.service.d
    install -m 644 /tmp/20-system-audio.conf /etc/systemd/system/wireplumber.service.d/20-system-audio.conf
    install -m 644 /tmp/apex-pipewire-ofono.conf /etc/dbus-1/system.d/apex-pipewire-ofono.conf
    install -m 644 /tmp/20-ivi-hdmi.conf /etc/pipewire/pipewire.conf.d/20-ivi-hdmi.conf
    install -d /etc/systemd/system/apex-ivi.service.d
    install -m 644 /tmp/30-pipewire-audio.conf /etc/systemd/system/apex-ivi.service.d/30-pipewire-audio.conf
    if [ -f /etc/pipewire/pipewire.conf.d/10-bluez.conf ]; then
        mv /etc/pipewire/pipewire.conf.d/10-bluez.conf /etc/pipewire/pipewire.conf.d/10-bluez.conf.disabled
    fi
    systemctl daemon-reload
    busctl call org.freedesktop.DBus / org.freedesktop.DBus ReloadConfig
    systemctl disable --now apex-hfp-daemon
    systemctl enable --now ofono
    systemctl restart pipewire
    systemctl restart wireplumber
    systemctl restart apex-ivi
    systemctl is-active ofono pipewire wireplumber apex-ivi
'
