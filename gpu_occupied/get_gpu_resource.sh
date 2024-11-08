#!/bin/bash

# 定义目标用户名
TARGET_USER="targetuser"  # 将 targetuser 替换为实际用户名

# 获取该用户当前占用的GPU进程数
function get_gpu_usage() {
    echo "当前 ${TARGET_USER} 占用的 GPU 数量如下："
    nvidia-smi --query-compute-apps=pid,gpu_uuid,used_memory --format=csv,noheader | grep "${TARGET_USER}"
    gpu_count=$(nvidia-smi --query-compute-apps=pid,gpu_uuid,used_memory --format=csv,noheader | grep "${TARGET_USER}" | wc -l)
    echo "总共占用了 $gpu_count 张 GPU."
}

# 杀掉指定数量的进程
function release_gpus() {
    read -p "需要释放多少张 GPU？" release_count

    if [ "$release_count" -gt "$gpu_count" ]; then
        echo "输入的数量超过了 ${TARGET_USER} 当前占用的 GPU 数量。将释放所有占用的 GPU 进程。"
        release_count=$gpu_count
    fi

    pids_to_kill=($(nvidia-smi --query-compute-apps=pid --format=csv,noheader | grep -v '^$' | head -n $release_count))

    for pid in "${pids_to_kill[@]}"; do
        echo "正在终止进程 PID: $pid..."
        kill_target_user "$pid"
        if [ $? -eq 0 ]; then
            echo "成功终止进程 PID: $pid."
        else
            echo "无法终止进程 PID: $pid，请确保拥有必要的权限。"
        fi
    done

    echo "成功释放了 $release_count 张 GPU."
}

# 执行主流程
get_gpu_usage
release_gpus
