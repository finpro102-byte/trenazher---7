#!/usr/bin/env bash
# Скачивает набор портретов Random User для офлайн-игры.
# Использование: bash tools/download_faces.sh 200
set -euo pipefail
cd "$(dirname "$0")/.."
N="${1:-200}"
mkdir -p assets/faces
for i in $(seq 1 "$N"); do
  f="assets/faces/face_$(printf '%04d' "$i").jpg"
  if [ ! -s "$f" ]; then
    gender="men"
    number=$(( (i - 1) % 99 ))
    if [ $((i % 2)) -eq 0 ]; then gender="women"; fi
    curl -fLsS --retry 2 --max-time 30 \
      "https://randomuser.me/api/portraits/${gender}/${number}.jpg" -o "$f"
  fi
  if [ $((i % 20)) -eq 0 ]; then echo "Скачано $i / $N"; fi
done
echo "Готово: $N портретов в assets/faces/"
echo "В lib/game_screen.dart установите: AssetFaceProvider(count: $N)"
