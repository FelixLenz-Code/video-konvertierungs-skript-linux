#!/bin/bash
# =============================================
# Video-Konvertierungs-Skript
# Autor: Felix Lenz
# Unterstützt durch: ChatGPT als Hilfstool
# Externes Tool: ffmpeg (https://ffmpeg.org/), verwendet zur Videokonvertierung
# Lizenzhinweis: ffmpeg ist unter LGPL/GPL lizenziert
# Beschreibung:
# Dieses Linux-Konvertierungstool sucht alle gängigen Videodateien
# (z.B. mp4, mkv, mov, avi, flv, wmv, m4v) im aktuellen
# Verzeichnis und konvertiert sie in den DNxHR HQX Codec.
# Es ist besonders hilfreich für den Einsatz in DaVinci Resolve unter Linux.
# Funktionen:
# - Prüft, ob ffmpeg installiert ist und installiert es ggf. plattformübergreifend
# - Live-Fortschrittsanzeige mit ETA
# - Überspringt bereits konvertierte Dateien
# - Ausgabe aller konvertierten Dateien im Ordner 'conv/'
# - Gesamtstatistik am Ende (konvertierte Dateien, übersprungene Dateien, Gesamtzeit)
# =============================================

# Farben definieren
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # keine Farbe

# --------------------------
# Einführung ausgeben
# --------------------------
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}        🎬 Video-Konvertierungs-Skript       ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo "Dieses Linux-Konvertierungstool sucht alle gängigen Videodateien"
echo "(z.B. mp4, mkv, mov, avi, flv, wmv, m4v) im aktuellen Verzeichnis"
echo "und konvertiert sie in den DNxHR HQX Codec."
echo "Besonders hilfreich für den Einsatz in DaVinci Resolve unter Linux."
echo ""
echo "Eigenschaften:"
echo " - 🔍 Prüft, ob ffmpeg installiert ist, und installiert es ggf. (plattformübergreifend)"
echo " - ⏳ Live-Fortschrittsanzeige mit ETA"
echo " - ⚠️ Überspringt bereits konvertierte Dateien"
echo " - 📂 Ausgabe aller konvertierten Dateien im Ordner 'conv/'"
echo " - 📝 Vor der Konvertierung werden alle zu bearbeitenden Dateien aufgelistet und um Bestätigung gebeten"
echo -e "${BLUE}=============================================${NC}"
echo ""

# --------------------------
# Prüfen ob ffmpeg installiert ist
# --------------------------
if command -v ffmpeg >/dev/null 2>&1; then
    echo -e "ℹ️  ${GREEN}ffmpeg ist bereits installiert.${NC}"
else
    echo -e "⚠️  ffmpeg ist nicht installiert. Installation wird gestartet..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        OS=$(uname -s)
    fi

    case "$OS" in
        ubuntu|debian|linuxmint|pop)
            sudo apt update && sudo apt install -y ffmpeg
            ;;
        fedora|centos|rhel|rocky|almalinux)
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y ffmpeg
            else
                sudo yum install -y ffmpeg
            fi
            ;;
        arch|manjaro)
            sudo pacman -Sy --noconfirm ffmpeg
            ;;
        opensuse*|suse)
            sudo zypper install -y ffmpeg
            ;;
        *)
            echo -e "❌ ${RED}Automatische ffmpeg-Installation wird für Ihr System nicht unterstützt.${NC}"
            exit 1
            ;;
    esac

    if command -v ffmpeg >/dev/null 2>&1; then
        echo -e "✅ ${GREEN}ffmpeg erfolgreich installiert.${NC}"
    else
        echo -e "❌ ${RED}ffmpeg konnte nicht installiert werden.${NC}"
        exit 1
    fi
fi

# --------------------------
# Fortschrittsanzeige
# --------------------------
progress_bar() {
    local cur=$1
    local total=$2
    local elapsed=$3
    local file_idx=$4
    local file_total=$5
    local filename=$6

    local percent=$(( cur * 100 / total ))
    (( percent > 100 )) && percent=100

    local filled=$(( percent / 2 ))
    local empty=$(( 50 - filled ))

    if (( cur > 0 )); then
        local rate=$(( elapsed / cur ))
        local remain=$(( (total - cur) * rate ))
    else
        local remain=0
    fi
    local eta_min=$(( remain / 60 ))
    local eta_sec=$(( remain % 60 ))

    printf "\r⏳ Datei %d/%d: %s\n" "$file_idx" "$file_total" "$filename"
    printf "["
    printf "${GREEN}%0.s#${NC}" $(seq 1 $filled)
    printf "${RED}%0.s-${NC}" $(seq 1 $empty)
    printf "] ${YELLOW}%3d%%${NC} | ETA: ${BLUE}%02d:%02d${NC}" "$percent" "$eta_min" "$eta_sec"
}

# --------------------------
# Videodateien sammeln
# --------------------------
video_exts=("mp4" "mkv" "mov" "avi" "flv" "wmv" "m4v" "MP4" "MKV" "MOV" "AVI" "FLV" "WMV" "M4V")
all_files=()
for ext in "${video_exts[@]}"; do
    for f in *."$ext"; do
        [ -e "$f" ] && all_files+=("$f")
    done
done

files_to_convert=()
skipped_files=0
for f in "${all_files[@]}"; do
    base=$(basename "$f")
    output="conv/${base%.*}.mov"
    if [ -e "$output" ]; then
        echo -e "⚠️  ${YELLOW}Überspringe bereits existierende Datei: $output${NC}"
        ((skipped_files++))
    else
        files_to_convert+=("$f")
    fi
done

total_files=${#files_to_convert[@]}
if [ "$total_files" -eq 0 ]; then
    echo -e "ℹ️  ${BLUE}Keine neuen Dateien zum Konvertieren.${NC}"
    exit 0
fi

# --------------------------
# Benutzerbestätigung
# --------------------------
mkdir -p conv

echo "---------------------------------------------"
echo -e "📝 Folgende $total_files Dateien werden konvertiert:"
for f in "${files_to_convert[@]}"; do
    echo " - $f"
done

while true; do
    read -p "Möchten Sie fortfahren? (j/N): " confirm
    confirm=${confirm,,}

    if [[ "$confirm" == "j" || "$confirm" == "ja" ]]; then
        break
    elif [[ "$confirm" == "n" || "$confirm" == "nein" || "$confirm" == "no" ]]; then
        # nur löschen, wenn Ordner leer
        if [ -d "conv" ] && [ -z "$(ls -A conv)" ]; then
            echo -e "ℹ️  Abgebrochen vom Benutzer. Leerer Ordner 'conv' wird gelöscht."
            rm -rf conv
        else
            echo -e "ℹ️  Abgebrochen vom Benutzer."
        fi
        exit 0
    else
        echo -e "${YELLOW}Ungültige Eingabe. Bitte 'j' zum Fortfahren oder 'n' zum Abbrechen eingeben.${NC}"
    fi
done

# --------------------------
# Konvertierung
# --------------------------
file_index=0
converted_files=0
start_total_ts=$(date +%s)

echo "---------------------------------------------"
echo -e "⏳ Starte Konvertierung ($total_files Dateien insgesamt)..."

for file in "${files_to_convert[@]}"; do
    ((file_index++))
    base=$(basename "$file")
    output="conv/${base%.*}.mov"

    echo -e "\n---------------------------------------------"
    echo -e "⏳ ($file_index/$total_files) Konvertiere: $base"

    duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file")
    duration=${duration%.*}
    start_ts=$(date +%s)

    while IFS='=' read -r key val; do
        case "$key" in
            out_time_ms)
                cur=$(( val / 1000000 ))
                (( cur > duration )) && cur=$duration
                now_ts=$(date +%s)
                elapsed=$(( now_ts - start_ts ))

                tput cuu1 2>/dev/null
                tput el 2>/dev/null
                progress_bar "$cur" "$duration" "$elapsed" "$file_index" "$total_files" "$base"
                ;;
        esac
    done < <(
        stdbuf -oL ffmpeg -hide_banner -loglevel error \
            -i "$file" -c:v dnxhd -profile:v dnxhr_hqx \
            -pix_fmt yuv422p10le -b:v 110M -c:a pcm_s16le "$output" \
            -progress pipe:1 -nostats 2>/dev/null
    )

    echo -e "\n✅ Fertig: $output"
    ((converted_files++))
done

# --------------------------
# Gesamtstatistik
# --------------------------
end_total_ts=$(date +%s)
total_elapsed=$((end_total_ts - start_total_ts))
total_min=$(( total_elapsed / 60 ))
total_sec=$(( total_elapsed % 60 ))

echo -e "\n---------------------------------------------"
echo -e "🎉 Alle Konvertierungen abgeschlossen."
echo -e "✅ Dateien konvertiert: ${GREEN}$converted_files${NC}"
echo -e "⚠️ Dateien übersprungen: ${YELLOW}$skipped_files${NC}"
echo -e "⏱️ Gesamtzeit: ${BLUE}$total_min min $total_sec sec${NC}"
