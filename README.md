# AtCoder コンテスト用 Docker 環境

AtCoder コンテストに参加するための Docker 環境です。  
ログイン、コンテスト開始、次の問題への遷移を効率的に行えるようセットアップされています。  
言語は C++, python のみ対応しています。

## 機能

- 必要なツールやコンパイラを備えた事前に構成された Dockerfile。
- VSCode の拡張機能 dev containers のセットアップ。
- コンテストの準備や管理を簡単にするためのスクリプト。
- 素早くコードを生成できるカスタムテンプレート。
- `env`配下のファイルやその他の設定を使用した自動環境設定。

## 前提条件

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Visual Studio Code](https://code.visualstudio.com/) (リモート開発の推奨エディタ)
  - VSCode 拡張機能 [dev containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

## ディレクトリ構成

```
atcoder_docker/
├── .clang-format          # C++ 用コード整形設定ファイル
├── .clang-tidy            # C++ 用静的コード解析の設定ファイル
├── .devcontainer          # VSCode 拡張機能 dev containers の設定ファイル
├── env                   # 環境変数の設定ファイル群
├── .vscode
├── Dockerfile
├── docker-compose.yml
├── scripts
└── templates/             # コンテスト提出用のコードテンプレート
```

## セットアップ手順

1. **Docker コンテナのビルドと起動**

   ```bash
   docker-compose up --build -d
   ```

1. **Docker コンテナにアクセスする**
   VSCode のウィンドウ左下の "open a remote window" のマークをクリックし、コンテナを開く

1. **環境の初期化**  
   コンテナ内で、以下のスクリプトを実行して環境を初期化する。
   ```bash
   source /workspace/scripts/init.sh
   ```

## Docker 内コマンドガイド

- コンテストの問題ダウンロード
  scc コマンドを実行すると以下を行います。

  - コンテストにアクセスして開始前か判定します。コンテスト開始前の場合、1 秒ごとにリトライして、OK の場合以下を実行します。
  - `workspace/contests` 配下にコンテスト id のディレクトリとさらにその配下に各問題のディレクトリを作成します。
  - 各問題のディレクトリに`/workspace/templates`配下のコーディングテンプレートをコピーします。
  - 1 問目の問題に`cd`して、main.cpp ファイルを開き、さらに問題の URL を開きます。

  ```bash
  scc <contest_id> [<problem_ids>]
  # ex. コンテストの問題を全てダウンロード
  scc abc100
  # コンテストの問題を指定してダウンロード
  scc abc100 a b c
  ```

- コンテスト中の問題切り替え
  問題のディレクトリにいる前提（ex.`/workspace/contests/abc100/a`）で、下記コマンドを実行すると、同じコンテスト ID の指定した問題のディレクトリに移動し、問題の URL を開きます。

  ```bash
  pwd # ex. /workspace/contests/abc100/b
  cdc <problem_id>
  # ex. cdc d
  ```

- コーディングテスト
  エイリアスを設定しています。
  各問題ディレクトリ`tests`ディレクトリがあり、配下にあるにサンプルの入出力テキストを使用してテストを実施します。

  ```bash
  pwd # ex. /workspace/contests/abc100/b
  # for C++
  tt: 'g++ -std=c++20 -o a.out main.cpp && oj t -d tests'
  # for python
  tp: 'oj t -c \"python3 main.py\" -d tests'
  ```

- コード提出
  エイリアスを設定しています。
  提出後、結果画面を開きます。
  ```bash
  pwd # ex. /workspace/contests/abc100/b
  # for C++
  ag: 'acc submit main.cpp'
  # for python
  ap: 'acc submit main.py -- --guess-python-interpreter pypy'
  ```

## 環境のシャットダウン

作業が終わったら、以下のコマンドでコンテナを停止し削除します。

```bash
docker-compose down
```

## トラブルシューティング

問題が発生した場合、以下のコマンドでコンテナを再ビルドしてみてください。

```bash
docker-compose down && docker-compose up --build -d
```
