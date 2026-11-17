# セットアップガイド

## 準備

1. Linux ホストに Docker と Docker Compose を用意し、PX-Q3U4 とアンテナ、
   内蔵リーダーで使用するカードを接続します。

2. ファームウェアのダウンロード
   ```sh
   scripts/fetch-firmware.sh
   ```
   PLEX の PX-Q3U4 ドライバーをダウンロードして `coax/firmware/it930x-firmware.bin` を取り出します。
   coax イメージの `fwextract` を使用します。ファームウェアは同梱していません。
   既存ファイルは `--force` を付けない限り上書きしません。

   詳細は[coax のファームウェア文書](https://github.com/Till0196/coax/blob/v0.1.5/docs/setup/firmware.md)を参照してください。
   同じ名前のファイルがイメージ内の `/lib/firmware` に存在する場合はそちらが優先されます。

3. 設定ファイルのセットアップ
   ```sh
   scripts/setup.sh
   ```
   サンプルから設定ファイル（`.env`、`mirakurun/config/tuners.yml`、`epgstation/config/*.yml`）をコピーします。
   既存ファイルは上書きされません。

   このスクリプトは以下のファイルも生成します：
   - `epgstation/config/recording-finish.sh`: 録画終了時に実行されるスクリプト（サンプルからコピー）
   - `epgstation/config/enc.js`: エンコード設定テンプレート（EPGStation リポジトリからダウンロード）

   **重要**: `.env` の 2 つのパスワードを別々の十分長いランダムな値に変更します。`.env` は公開しないでください。
   初期化済みの MariaDB のパスワードは `.env` の変更だけでは変更されません。

4. チャンネル設定の生成
   ```sh
   scripts/generate-channels.sh
   ```
   チャンネル設定を生成します。詳細は「チャンネル設定」セクションを参照してください。
   coaxd だけを一時的に起動してスキャンするので、スタック全体の起動前に実行できます。

5. EPGStation イメージをビルド
   ```sh
   docker compose build
   ```

   Dockerfile を変更した場合は、再度 `docker compose build` を実行してから起動してください。

6. スタックを起動
   ```sh
   docker compose up -d
   ```

## チャンネル設定

### tuners.yml の設定

`mirakurun/config/tuners.yml`（`tuners.sample.yml` のコピー）には地上 4・衛星 4 のチューナーを設定しています。
実際のチューナーの割り当ては coaxd が行います。衛星アンテナへの給電は既定では無効です。
必要な場合は給電方式を確認し、衛星チューナーのコマンドに `--lnb-power` を設定してください。

### channels.yml の生成

`mirakurun/config/channels.yml` はスキャン結果から生成します。初期セットアップ後や
放送局のチャンネル再編時に、いつでも再実行できます（生成後は Mirakurun の設定画面などで調整もできます）：

```sh
scripts/generate-channels.sh
scripts/generate-channels.sh -d ISDBT -- --analysis-time 10
scripts/generate-channels.sh -- --lnb-power high   # 衛星アンテナへの給電が必要な場合
```

スクリプトは動作中の Mirakurun を止め、coaxd 内で `coax scan --discover` と
`coax export` を実行して `mirakurun/config/channels.yml` を置き換え、Mirakurun を起動し直します。
coaxd が実行前に停止していた場合、スキャン後にそのコンテナを停止・削除します。
すでに動作していた coaxd はそのまま残します。
既存ファイルは `channels.yml.bak.<日時>` に退避されます。詳細は `-h` を参照してください。

### チューナーやカードリーダーの確認

```sh
docker compose exec -T coaxd coax list --no-start --tuners
docker compose exec -T coaxd coax card --no-start --list
```

スキャンは時間がかかります。PX-Q3U4 は 2 つの USB デバイスとして認識されるため、
カードリーダーの一覧には複数の候補が表示されます。カードの確認時に `coax card` が
リーダーの指定を求めた場合は `--reader` で選択してください。

詳しくは [coax のカードリーダー文書](https://github.com/Till0196/coax/blob/v0.1.5/docs/reference/card-reader.md)を参照してください。
