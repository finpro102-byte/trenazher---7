#!/usr/bin/env bash
# Загружает портреты во время сборки. Они будут включены в APK,
# поэтому после установки интернет игре не понадобится.
set -euo pipefail
cd "$(dirname "$0")/.."
N="${1:-60}"
mkdir -p assets/faces
for i in $(seq 1 "$N"); do
  f="assets/faces/face_$(printf '%04d' "$i").jpg"
  if [ ! -s "$f" ]; then
    gender="men"
    number=$(( (i - 1) / 2 ))
    if [ $((i % 2)) -eq 0 ]; then gender="women"; fi
    curl -fLsS --retry 3 --retry-delay 1 --max-time 30 \
      "https://randomuser.me/api/portraits/${gender}/${number}.jpg" -o "$f"
  fi
  if [ $((i % 20)) -eq 0 ]; then echo "Скачано $i / $N"; fi
done
echo "Готово: $N портретов включатся в APK для офлайн-работы."
