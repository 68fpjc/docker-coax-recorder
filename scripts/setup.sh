#!/usr/bin/env bash
# サンプルファイルから初期設定ファイルをコピーする。既存ファイルは上書きしない。
set -euo pipefail

cd "$(dirname "$0")/.."

copy() {
  if [ -e "$2" ]; then
    echo "skip: $2 (既に存在します)"
  else
    cp "$1" "$2"
    echo "created: $2"
  fi
}

copy .env.example .env
copy mirakurun/config/tuners.sample.yml mirakurun/config/tuners.yml
for f in config operatorLogConfig serviceLogConfig epgUpdaterLogConfig; do
  copy "epgstation/config/$f.sample.yml" "epgstation/config/$f.yml"
done
copy epgstation/config/recording-finish.sample.sh epgstation/config/recording-finish.sh

# EPGStation のエンコード設定をダウンロード（存在しない場合のみ）
if [ ! -e "epgstation/config/enc.js" ]; then
  echo "Downloading EPGStation enc.js template..."
  curl -fsSL https://raw.githubusercontent.com/l3tnun/docker-mirakurun-epgstation/v3/epgstation/config/enc.js.template > epgstation/config/enc.js
  echo "created: epgstation/config/enc.js"
else
  echo "skip: epgstation/config/enc.js (既に存在します)"
fi

cat <<MSG

次の手順:
  1. .env の 2 つのパスワードを別々の十分長いランダムな値に変更する
  2. scripts/generate-channels.sh でチャンネル設定を生成する
  3. docker compose build でイメージをビルド
  4. docker compose up -d で起動する
MSG
