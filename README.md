# coax + Mirakurun + EPGStation

PX-Q3U4 を coax の直接 USB バックエンドで利用する Docker Compose 構成です。

- **coaxd**: チューナーと内蔵カードリーダーを管理
- **Mirakurun**: 選局と B25 デコード
- **EPGStation**: 番組表と録画

## 前提条件

PX-Q3U4 がホストの `px4_drv` などにバインドされていると、直接 USB 経由では使用できない場合があります。
既存の録画環境と競合しないように確認してください。詳細は
[coax の OS 設定](https://github.com/Till0196/coax/blob/v0.1.5/docs/setup/os.md)を参照してください。

## クイックスタート

```sh
# 1. 環境準備
# Linux ホストに Docker と Docker Compose を用意し、PX-Q3U4 とアンテナ、
# 内蔵リーダー用カードを接続します。詳細は SETUP.md を参照してください

# 2. ファームウェアをダウンロード
scripts/fetch-firmware.sh

# 3. 設定ファイルをセットアップ
scripts/setup.sh
# .env のパスワードを変更してください

# 4. チャンネル設定を生成
scripts/generate-channels.sh

# 5. EPGStation イメージをビルド
docker compose build

# 6. スタックを起動
docker compose up -d
```

## ドキュメント

- [SETUP.md](./SETUP.md) - 詳細なセットアップ手順とチャンネル設定
- [NOTES.md](./NOTES.md) - 利用と制限、技術的な注意事項
