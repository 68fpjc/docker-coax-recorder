# 利用と制限

## アクセス情報

- **Mirakurun**: `http://<ホストアドレス>:40772/`
- **EPGStation**: `http://<ホストアドレス>:8888/`
  - Socket.IO: `http://<ホストアドレス>:8889/` (内部通信用)

公開ポートは既定ですべてのホストインターフェースにバインドされます。
信頼できるネットワークに限定するか、Compose のポート設定やファイアウォールでアクセスを制限してください。

## coax

### 初期化コンテナ

`coax-bin` は共有ボリュームに `coax` をコピーして正常終了します。
Mirakurun は Compose の `service_completed_successfully` によりコピー完了を待ちます。
coax イメージ更新後は初期化コンテナを再実行してください。

### ソケット共有

`coaxd` と `coax-pcsc` のソケットはそれぞれ共有ボリュームに置きます。
PC/SC ソケットは所有者のみアクセス可能なため、現状は公式イメージの root 実行を前提とします。
PC/SC の起動順序は制御しますが、起動後のデコーダー・カードの利用可能性を保証するものではありません。

## Mirakurun

### チューナーとチャンネル設定

`mirakurun/config/tuners.yml` はチューナーの定義を記載します。サンプルから生成されたファイルは
地上 4・衛星 4 のチューナーを設定していますが、実際のチューナー割り当ては coax が行うため、
カスタマイズの必要はほとんどありません。

`mirakurun/config/channels.yml` はチャンネル情報を記載します。これは `scripts/generate-channels.sh`
で coax のスキャン結果から生成されます。初期セットアップ後や放送局のチャンネル再編時に
再実行できます。詳細は SETUP.md の「チャンネル設定」セクションを参照してください。

### ログ確認

Mirakurun のログは以下で確認できます：

```sh
docker compose logs -f mirakurun
```

### coax との連携

Mirakurun は coaxd と coax-pcsc のソケットを通じて通信します。これらのコンテナに依存し、
起動順序は自動的に制御されます。

## EPGStation

### ファイルシステム

`epgstation/Dockerfile` は `l3tnun/epgstation:latest` をベースに Debian の FFmpeg を追加し、
`config.yml` から `/usr/bin/ffmpeg` と `/usr/bin/ffprobe` を使います。
利用できるエンコーダーは以下のコマンドで確認できます：

```sh
docker compose exec epgstation ffmpeg -encoders
```

### ログとバックアップ

EPGStation のログは標準出力に出ます。以下で確認できます：

```sh
docker compose logs -f epgstation
```

MariaDB のデータはホストの `mysql/data/` に保存され、`docker compose down -v` でも削除されません。
ただしホスト上での削除やディスク障害には備えられないため、設定、録画、番組データとともに
別途バックアップしてください。MariaDB の実行ユーザーが保存先に書き込める必要があります。
