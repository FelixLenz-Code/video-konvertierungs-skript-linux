# video-konvertierungs-skript-linux
Ein Linux Tool um Videomaterial in einen edited codec umzuwandeln, sodass Davinci Resolve (Basic Version) unter Linux damit umgehen kann.

# 🎬 Linux Video-Konvertierungs-Skript

**Autor:** Felix Lenz  
**Unterstützt durch:** ChatGPT als Hilfstool  

Dieses Linux-Konvertierungstool sucht alle gängigen Videodateien (z.B. mp4, mkv, mov, avi, flv, wmv, m4v) im aktuellen Verzeichnis und konvertiert sie **in den DNxHR HQX Codec**.  
Es ist besonders hilfreich für den Einsatz in **DaVinci Resolve unter Linux**.  
Das Skript zeigt eine Live-Fortschrittsanzeige, überspringt bereits konvertierte Dateien und gibt am Ende eine Gesamtstatistik aus.

---

## 🚀 Features

```text
- Prüft, ob ffmpeg installiert ist und installiert es ggf. plattformübergreifend
- Live-Fortschrittsanzeige mit ETA pro Datei
- Überspringt bereits konvertierte Dateien
- Ausgabe aller konvertierten Dateien im Ordner 'conv/'
- Vor der Konvertierung werden alle zu bearbeitenden Dateien aufgelistet und um Bestätigung gebeten
- Gesamtstatistik am Ende (konvertierte Dateien, übersprungene Dateien, Gesamtzeit)
- Farbiges Terminal mit Icons für bessere Übersicht
