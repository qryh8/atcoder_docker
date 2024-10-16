#!/bin/bash

# ログ出力用の設定
log_info() { echo -e "\e[36m[INFO]\e[0m $1"; }
log_warning() { echo -e "\e[33m[WARNING]\e[0m $1"; }
log_success() { echo -e "\e[32m[✓]\e[0m $1"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }

# 引数でコンテストIDとオプションの問題を受け取る
CONTEST_ID=$1
shift
PROBLEM_LIST=("$@")  # 残りの引数を問題IDとして配列に格納
[ -z "$CONTEST_ID" ] && log_error "Usage: $0 <contest_id> [problem_id(s)]"

# コンテストディレクトリに移動
cd /workspace/contests/ || log_error "Failed to navigate to /workspace/contests/."

# コンテストページがアクセス可能になるまで待機
start_time_str=$(curl -s "https://atcoder.jp/contests/${CONTEST_ID}" | grep -oP 'var startTime = moment\("\K[^"]+')
start_time=$(date -d "$start_time_str" +%s)

log_info "Waiting for contest ${CONTEST_ID} to become accessible at $start_time_str."
while [ "$(date +%s)" -lt "$start_time" ]; do
  echo -n "." 
  sleep 1
done

# コンテストがアクセス可能になったときのログ
log_success "Contest ${CONTEST_ID} is now accessible!"

# AtCoder CLIを使って指定された問題を個別にダウンロード
if [ ${#PROBLEM_LIST[@]} -eq 0 ]; then
    log_info "Downloading all problems for ${CONTEST_ID}..."
    acc new $CONTEST_ID || log_error "Failed to download all problems for ${CONTEST_ID}."
else
    log_info "Downloading specified problems: ${PROBLEM_LIST[*]}..."
    acc new $CONTEST_ID -t "${PROBLEM_LIST[0]}" || log_error "Failed to download ${PROBLEM_LIST[0]}."
    
    # 2問目以降の問題を追加
    cd /workspace/contests/$CONTEST_ID || log_error "Failed to navigate to contest directory."
    for problem in "${PROBLEM_LIST[@]:1}"; do
        acc add -f -t "$problem" || log_warning "Failed to add problem $problem."
    done
fi

# 各問題ディレクトリにテンプレートをコピー
TEMPLATE_FILES="/workspace/templates/*"
for PROBLEM_DIR in /workspace/contests/$CONTEST_ID/*; do
  [[ -d "$PROBLEM_DIR" ]] && cp -r $TEMPLATE_FILES "$PROBLEM_DIR" 2>/dev/null
done
log_success "Templates copied to all relevant problem directories."

log_success "Contest setup complete! Navigate to /workspace/contests/$CONTEST_ID to start solving problems."
