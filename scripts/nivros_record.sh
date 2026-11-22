#!/usr/bin/env bash
set -u

AUDIO_MODE="${1:-system}"     # none | system | sys_mic
RES_MODE="${2:-native}"       # native | 360 | 720 | 1080 | 1440 | 2160

mkdir -p "$HOME/Videos"
STAMP="$(date +%Y%m%d_%H%M%S)"
RAW_FILE="/tmp/nivros_raw_${STAMP}.mkv"
OUT_FILE="$HOME/Videos/NivrOS_Rec_${STAMP}.mp4"

MOD_NULL=""
MOD_LOOP_SYS=""
MOD_LOOP_MIC=""

cleanup_audio() {
    [ -n "$MOD_LOOP_MIC" ] && pactl unload-module "$MOD_LOOP_MIC" >/dev/null 2>&1 || true
    [ -n "$MOD_LOOP_SYS" ] && pactl unload-module "$MOD_LOOP_SYS" >/dev/null 2>&1 || true
    [ -n "$MOD_NULL" ] && pactl unload-module "$MOD_NULL" >/dev/null 2>&1 || true
}
trap cleanup_audio EXIT

AUDIO_ARGS=()
if [ "$AUDIO_MODE" = "system" ]; then
    DEF_SINK="$(pactl get-default-sink 2>/dev/null || true)"
    if [ -n "$DEF_SINK" ]; then
        AUDIO_ARGS=(-a"${DEF_SINK}.monitor")
    else
        AUDIO_ARGS=(-a)
    fi
elif [ "$AUDIO_MODE" = "sys_mic" ]; then
    DEF_SINK="$(pactl get-default-sink 2>/dev/null || true)"
    DEF_SRC="$(pactl get-default-source 2>/dev/null || true)"
    MOD_NULL="$(pactl load-module module-null-sink sink_name=nivros_rec_mix sink_properties=device.description=NivrOS_Rec_Mix 2>/dev/null || true)"
    if [ -n "$MOD_NULL" ]; then
        [ -n "$DEF_SINK" ] && MOD_LOOP_SYS="$(pactl load-module module-loopback source="${DEF_SINK}.monitor" sink=nivros_rec_mix latency_msec=20 2>/dev/null || true)"
        [ -n "$DEF_SRC" ] && MOD_LOOP_MIC="$(pactl load-module module-loopback source="$DEF_SRC" sink=nivros_rec_mix latency_msec=20 2>/dev/null || true)"
        AUDIO_ARGS=(-anivros_rec_mix.monitor)
    else
        AUDIO_ARGS=(-a)
    fi
fi

# 1. Rekam mentah ultra-ringan ke MKV (aman dari korup & tidak membebani CPU)
wf-recorder -c libx264 -p preset=ultrafast -p crf=18 "${AUDIO_ARGS[@]}" -f "$RAW_FILE" || true

# 2. Konversi otomatis ke MP4 standar universal Android / iOS / WhatsApp
if [ -s "$RAW_FILE" ]; then
    case "$RES_MODE" in
        360|720|1080|1440|2160)
            VF_CHAIN="scale=-2:${RES_MODE}:flags=lanczos,scale=trunc(iw/2)*2:trunc(ih/2)*2,fps=30,format=yuv420p"
            ;;
        *)
            VF_CHAIN="scale=trunc(iw/2)*2:trunc(ih/2)*2,fps=30,format=yuv420p"
            ;;
    esac

    if ffmpeg -y -hide_banner -loglevel error -i "$RAW_FILE" \
        -vf "$VF_CHAIN" \
        -c:v libx264 -profile:v main -level:v 4.1 -preset veryfast -crf 23 \
        -pix_fmt yuv420p -color_range tv -colorspace bt709 -color_primaries bt709 -color_trc bt709 \
        -c:a aac -b:a 128k -ar 44100 -ac 2 \
        -movflags +faststart "$OUT_FILE"; then
        rm -f "$RAW_FILE"
        notify-send "NivrOS Screen Recorder" "Video siap dikirim ke WA: $(basename "$OUT_FILE")" 2>/dev/null || true
    else
        mv -f "$RAW_FILE" "${OUT_FILE%.mp4}.mkv"
    fi
fi
