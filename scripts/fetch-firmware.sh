#!/usr/bin/env bash
# ドライバーパッケージ (既定: PLEX PX-Q3U4) からファームウェアを取り出し coax/firmware/ に配置する。
set -euo pipefail

cd "$(dirname "$0")/.."

DEFAULT_URL=https://plex-net.co.jp/wp-content/uploads/2025/06/202104_PX-Q3U4_Driver.zip
URL=$DEFAULT_URL
OUT_DIR=coax/firmware
# .env が未作成でもイメージ名を取得できるよう、必須変数にダミー値を渡す。
IMAGE=$(MYSQL_PASSWORD=- MYSQL_ROOT_PASSWORD=- docker compose config --images coaxd)

FORCE=

usage() {
  echo "Usage: $0 [--force] [URL]"
  echo "  URL      ドライバーパッケージの URL (既定: PX-Q3U4 用ドライバー)"
  echo "  --force  既存のファームウェアを上書きする"
}

while [ $# -gt 0 ]; do
  case $1 in
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "不明なオプション: $1" >&2; usage >&2; exit 2 ;;
    *) URL=$1; shift ;;
  esac
done

# fwextract は拡張子でも形式を判断するので、URL のファイル名を保つ。
pkg=$(basename "${URL%%[?#]*}")

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "==> ドライバーをダウンロードします"
curl -fL --retry 3 -o "$work/$pkg" "$URL"

echo "==> fwextract でファームウェアを取り出します"
mkdir "$work/out"
docker run --rm --entrypoint fwextract -v "$work:/work" "$IMAGE" \
  --all --output /work/out "/work/$pkg"

# ファイル名は fwextract が決めるので、出力されたものをそのまま配置する。
mkdir -p "$OUT_DIR"
shopt -s nullglob
files=("$work"/out/*)
if [ ${#files[@]} -eq 0 ]; then
  echo "エラー: ファームウェアを取り出せませんでした" >&2
  exit 1
fi
for f in "${files[@]}"; do
  dest="$OUT_DIR/$(basename "$f")"
  if [ -e "$dest" ] && [ -z "$FORCE" ]; then
    echo "skip: $dest (既に存在します。上書きは --force)"
  else
    install -m 644 "$f" "$dest"
    echo "配置しました: $dest"
  fi
done
