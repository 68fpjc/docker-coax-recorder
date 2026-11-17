#!/usr/bin/env bash
# coax scan --discover と coax export で mirakurun/config/channels.yml を生成する。
set -euo pipefail

cd "$(dirname "$0")/.."

OUTPUT=mirakurun/config/channels.yml
DISCOVER=ISDBT,ISDBS
CHANNEL_NAME=scanned
SCAN_ARGS=()
KEEP_SCAN=
RESTART_MIRAKURUN=1

usage() {
  cat <<EOF
Usage: $0 [options] [-- 追加の coax scan 引数]

  -o, --output FILE      出力先 (既定: $OUTPUT)
  -d, --discover LIST    スキャンする伝送方式 (既定: $DISCOVER)
  -n, --channel-name V   coax export の --channel-name: scanned|transponder (既定: $CHANNEL_NAME)
  -k, --keep-scan FILE   スキャン結果の JSON を FILE にも保存する
      --no-restart       完了後に Mirakurun を起動し直さない
  -h, --help

例:
  $0
  $0 -d ISDBT -- --analysis-time 10
  $0 -- --lnb-power high
EOF
}

while [ $# -gt 0 ]; do
  case $1 in
    -o|--output) OUTPUT=$2; shift 2 ;;
    -d|--discover) DISCOVER=$2; shift 2 ;;
    -n|--channel-name) CHANNEL_NAME=$2; shift 2 ;;
    -k|--keep-scan) KEEP_SCAN=$2; shift 2 ;;
    --no-restart) RESTART_MIRAKURUN=; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; SCAN_ARGS=("$@"); break ;;
    *) echo "不明なオプション: $1" >&2; usage >&2; exit 2 ;;
  esac
done

dc() { docker compose "$@"; }

mirakurun_running=$(dc ps --status running -q mirakurun)
coaxd_running=$(dc ps --status running -q coaxd)

# スキャン中はチューナーを占有するため、動作中なら Mirakurun を止める。
mirakurun_was_running=
if [ -n "$mirakurun_running" ]; then
  echo "==> Mirakurun を停止します"
  dc stop mirakurun
  mirakurun_was_running=1
fi

cleanup() {
  local status=$?
  if [ -z "$coaxd_running" ] && [ -n "$coaxd_start_attempted" ]; then
    echo "==> coaxd コンテナを停止・削除します"
    if ! dc rm -sf coaxd; then
      echo "エラー: coaxd コンテナを削除できませんでした" >&2
      status=1
    fi
  fi
  if [ -n "$mirakurun_was_running" ] && [ -n "$RESTART_MIRAKURUN" ]; then
    echo "==> Mirakurun を起動します"
    if ! dc start mirakurun; then
      echo "エラー: Mirakurun を起動できませんでした" >&2
      status=1
    fi
  fi
  if ! rm -f "${scan_tmp:-}" "${out_tmp:-}"; then
    echo "エラー: 一時ファイルを削除できませんでした" >&2
    status=1
  fi
  return "$status"
}
coaxd_start_attempted=
trap cleanup EXIT

echo "==> coaxd を起動します"
coaxd_start_attempted=1
dc up -d --no-deps --wait coaxd

mkdir -p "$(dirname "$OUTPUT")"
scan_tmp=$(mktemp)
out_tmp=$(mktemp "$OUTPUT.XXXXXX")

echo "==> スキャン中 (--discover=$DISCOVER)。数分かかります"
dc exec -T coaxd coax scan --no-start --discover="$DISCOVER" --restart --output - \
  ${SCAN_ARGS[@]+"${SCAN_ARGS[@]}"} >"$scan_tmp"

echo "==> channels.yml を書き出します"
dc exec -T coaxd coax export --format mirakurun --input - \
  --channel-name "$CHANNEL_NAME" --output - <"$scan_tmp" >"$out_tmp"

if ! grep -q '^- ' "$out_tmp"; then
  echo "エラー: 出力にチャンネルがありません。既存ファイルは変更しません" >&2
  exit 1
fi

if [ -n "$KEEP_SCAN" ]; then
  cp "$scan_tmp" "$KEEP_SCAN"
fi

if [ -f "$OUTPUT" ]; then
  backup="$OUTPUT.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$OUTPUT" "$backup"
  echo "==> 既存ファイルを $backup に退避しました"
fi

chmod 644 "$out_tmp"
mv "$out_tmp" "$OUTPUT"
echo "==> 生成しました: $OUTPUT ($(grep -c '^- ' "$OUTPUT") チャンネル)"
