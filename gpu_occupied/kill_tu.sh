# 定义一个函数，方便调用 kill_target_user_process
kill_target_user() {
    if [ -z "$1" ]; then
        echo "Usage: kill_target_user <PID>"
        return 1
    fi
    /usr/local/bin/kill_target_user_process "$1"
}