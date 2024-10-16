#!/bin/bash

# Function for log
log_info() { echo -e "\e[1;36m[INFO] $1\e[0m"; }
log_warning() { echo -e "\e[1;33m[WARNING] $1\e[0m"; }
log_success() { echo -e "\e[1;32m[✓] $1\e[0m"; }
log_error() { echo -e "\e[1;31m[ERROR] $1\e[0m"; }

log_info "🚀 Starting initialization script..."

# env ファイルが存在する場合、読み込む
ATCODER_USERNAME=
ATCODER_PASSWORD=
ENV_FILE="/workspace/env/.secrets"
if [ ! -f "$ENV_FILE" ]; then
    log_info "env/.secrets file not found. Please enter your AtCoder login details."
else
    export $(grep -v '^#' "$ENV_FILE" | xargs)
    log_success "env/.secrets file already exists."
fi

# 未設定の場合、ログイン情報（ユーザー名）を入力
isUserNameSet=false
if [ -z "$ATCODER_USERNAME"]; then
    read -p "AtCoder Username: " ATCODER_USERNAME
    isUserNameSet=true
fi

# 未設定の場合、ログイン情報（パスワード）を入力
isPasswordSet=false
if [ -z "$ATCODER_PASSWORD"]; then
    read -sp "AtCoder Password: " ATCODER_PASSWORD
    isPasswordSet=true
fi

echo ""

# Login to AtCoder CLI
log_info "Checking AtCoder CLI login status..."
if acc session 2>&1 | grep -q "not login"; then
    log_info "Logging into AtCoder CLI..."
    expect <<EOF
    spawn acc login
    expect "*username:*"
    send "$ATCODER_USERNAME\r"
    sleep 1
    expect "*password:*"
    send "$ATCODER_PASSWORD\r"
    expect eof
EOF
    if acc session 2>&1 | grep -q "not login"; then
        log_error "Failed to log in to AtCoder CLI."
    else
        # 未設定だったログイン情報を env/.secrets に書き込む
        if $isUserNameSet; then
            echo "ATCODER_USERNAME=$ATCODER_USERNAME" >> $ENV_FILE
        fi
        if $isPasswordSet; then
            echo "ATCODER_PASSWORD=$ATCODER_PASSWORD" >> $ENV_FILE
        fi
        log_success "Successfully logged into AtCoder CLI."
    fi
else
    log_success "AtCoder CLI is already logged in."
fi

# Set default task choice to 'all'
log_info "Setting default task choice to 'all'..."
acc config default-task-choice all
log_success "Configured default-task-choice to 'all'."

# Prevent 429 error by adding a sleep
sleep 1

# Login to Online Judge Tools
log_info "Checking Online Judge Tools login status..."
if oj login --check https://atcoder.jp 2>&1 | grep -q "You have already signed in."; then
    log_success "Online Judge Tools is already logged in."
else
    log_info "Logging into Online Judge Tools..."
    expect <<EOF
    spawn oj login https://atcoder.jp
    expect "Username: "
    send "$ATCODER_USERNAME\r"
    sleep 1
    expect "Password: "
    send "$ATCODER_PASSWORD\r"
    expect eof
EOF
    # 再確認
    if oj login --check https://atcoder.jp 2>&1 | grep -q "You have already signed in."; then
        log_success "Successfully logged into Online Judge Tools."
    else
        log_error "Failed to log in to Online Judge Tools."
    fi
fi

log_info "Updating functions and aliases in .bashrc..."

add_to_bashrc() {
    local content="$1"
    local function_name="$2"
    if ! grep -q "${function_name}()" ~/.bashrc; then
        echo "$content" >> ~/.bashrc
        log_success "Added '$function_name' to .bashrc."
    else
        log_success "'$function_name' is already present in .bashrc."
    fi
}

# 共通関数: 問題のURLを開く
add_to_bashrc '
open_problem_url() {
    local URL=$1
    if command -v xdg-open &> /dev/null; then
        xdg-open "$URL"
    elif command -v open &> /dev/null; then
        open "$URL"
    elif command -v start &> /dev/null; then
        start "$URL"
    else
        echo "No suitable command found to open the URL: $URL"
    fi
}
' "open_problem_url()"

# 共通関数: contest.acc.json から指定ディレクトリのURLを抽出
add_to_bashrc '
extract_problem_url() {
    local CONTEST_DIR="$1"
    local PROBLEM_DIR="$2"
    local CONFIG_FILE="${CONTEST_DIR}/contest.acc.json"

    # contest.acc.json の存在確認
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file not found in ${CONTEST_DIR}."
        return 1
    fi

    # jq を用いてURLを取得
    local PROBLEM_URL=$(jq -r --arg PROBLEM_DIR "$PROBLEM_DIR" \
        ".tasks[] | select(.directory.path == \$PROBLEM_DIR) | .url" "$CONFIG_FILE")

    # URL の取得に失敗した場合
    if [ -z "$PROBLEM_URL" ]; then
        echo "No problem URL found for directory: $PROBLEM_DIR."
        return 1
    fi

    echo "$PROBLEM_URL"
}
' "extract_problem_url()"

# scc (setupContest and cd) 関数を.bashrcに追加
add_to_bashrc '
scc() {
    local CONTEST_ID=$1
    shift
    local PROBLEM_LIST=("$@")
    if [ -z "$CONTEST_ID" ]; then
        echo "Usage: scc <contest_id> [problem_id(s)]"
        return 1
    fi

    /workspace/scripts/setupContest.sh $CONTEST_ID "${PROBLEM_LIST[@]}"
    local CONTEST_DIR="/workspace/contests/$CONTEST_ID"
    cd $CONTEST_DIR

    local FIRST_PROBLEM_DIR=$(ls -d * | head -n 1)
    [ -n "$FIRST_PROBLEM_DIR" ] && cd "$FIRST_PROBLEM_DIR" && code main.cpp

    # extract_problem_url を使って URL を取得
    local PROBLEM_URL=$(extract_problem_url "$CONTEST_DIR" "$FIRST_PROBLEM_DIR")
    if [ $? -eq 0 ]; then
        open_problem_url "$PROBLEM_URL"
    fi
}
' "scc()"

# cdc function: Navigate to another problem directory and open main.cpp
add_to_bashrc '
cdc() {
    local TARGET_DIR=$1

    # 引数が指定されていない場合のエラー処理
    if [ -z "$TARGET_DIR" ]; then
        echo "Usage: cdc <problem_dir>"
        return 1
    fi

    # 親ディレクトリ（コンテストディレクトリ）のパスを取得
    local CONTEST_DIR=$(dirname "$PWD")

    # extract_problem_url を使って URL を取得
    local PROBLEM_URL=$(extract_problem_url "$CONTEST_DIR" "$TARGET_DIR")
    if [ $? -ne 0 ]; then
        return 1
    fi

    # ディレクトリ移動とファイルオープン
    if cd ../"$TARGET_DIR"; then
        if [ -f "main.cpp" ]; then
            code main.cpp
        elif [ -f "main.py" ]; then
            code main.py
        else
            echo "No source file (main.cpp or main.py) found in $TARGET_DIR."
        fi
    else
        echo "Failed to navigate to directory: $TARGET_DIR."
        return 1
    fi

    # 問題の URL を開く
    open_problem_url "$PROBLEM_URL"
}
' "cdc()"

# Update aliases in .bashrc
update_alias() {
    local alias_name=$1
    local alias_command=$2
    sed -i "/alias $alias_name=/d" ~/.bashrc
    echo "alias $alias_name='$alias_command'" >> ~/.bashrc
}

update_alias "ll" "ls -l"
update_alias "tt" "g++ -std=c++20 -o a.out main.cpp && oj t -d tests"
update_alias "ag" "acc submit main.cpp"
update_alias "tp" "oj t -c \"python3 main.py\" -d tests"
update_alias "ap" "acc submit main.py -- --guess-python-interpreter pypy"

log_success "Aliases have been updated successfully."
echo " - ll: 'ls -l'"
echo " - tt: 'g++ -std=c++20 -o a.out main.cpp && oj t -d tests'"
echo " - ag: 'acc submit main.cpp'"
echo " - tp: 'oj t -c \"python3 main.py\" -d tests'"
echo " - ap: 'acc submit main.py -- --guess-python-interpreter pypy'"

source ~/.bashrc

# custom prompt
export PS1='$(basename $(dirname $PWD))/$(basename $PWD) # '

# Create contest directory
CONTEST_DIR="/workspace/contests"
mkdir -p $CONTEST_DIR
log_success "Contest directory created at $CONTEST_DIR."

log_success "Initialization script completed successfully!"
