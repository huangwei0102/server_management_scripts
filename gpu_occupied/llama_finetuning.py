import argparse
import os
import subprocess
import sys
import time
from math import sqrt
from multiprocessing import Array, Lock, Process, Value

import torch


class GPUGet:
    def __init__(
        self, min_gpu_number, max_gpu_number, gpu_occupy_mem, time_interval, duration_hours, gpu_mem_threshold
    ):
        self.occupied_num = Value("i", 0)
        self.occupied_gpus = Array("i", [-1 for _ in range(8)])
        self.min_gpu_number = min_gpu_number
        self.max_gpu_number = max_gpu_number
        self.gpu_occupy_mem = gpu_occupy_mem
        self.time_interval = time_interval
        self.duration_hours = duration_hours
        self.gpu_mem_threshold = gpu_mem_threshold
        self.gpu_idle_times = {}  # 记录每个GPU的空闲起始时间

    def get_gpu_mem(self, gpu_id):
        gpu_query = subprocess.check_output(["nvidia-smi", "--query-gpu=memory.used", "--format=csv,nounits,noheader"])
        gpu_memory = [int(x) for x in gpu_query.decode("utf-8").split("\n")[:-1]]
        return gpu_memory[gpu_id]

    def get_free_gpus(self) -> list:
        gpu_query = subprocess.check_output(["nvidia-smi", "--query-gpu=memory.used", "--format=csv,nounits,noheader"])
        gpus_memory = [int(x) for x in gpu_query.decode("utf-8").split("\n")[:-1]]
        free_gpus = [i for i, mem in enumerate(gpus_memory) if mem <= self.gpu_mem_threshold]
        return free_gpus

    def get_gpu_info(self):
        gpu_status = os.popen("nvidia-smi | grep %").read().split("|")[1:]
        gpu_dict = dict()
        for i in range(len(gpu_status) // 4):
            index = i * 4
            gpu_state = str(gpu_status[index].split("   ")[2].strip())
            gpu_power = int(gpu_status[index].split("   ")[-1].split("/")[0].split("W")[0].strip())
            gpu_memory = int(gpu_status[index + 1].split("/")[0].split("M")[0].strip())
            gpu_dict[i] = (gpu_state, gpu_power, gpu_memory)
        return gpu_dict

    def monitor_and_occupy(self):
        lock = Lock()
        while True:
            free_gpus = self.get_free_gpus()
            current_time = time.time()
            
            for gpu_id in free_gpus:
                # 记录空闲GPU的开始空置时间
                if gpu_id not in self.gpu_idle_times:
                    self.gpu_idle_times[gpu_id] = current_time
                # 如果空置时间超过1小时（3600秒）
                elif current_time - self.gpu_idle_times[gpu_id] >= 3600:
                    # 启动占用GPU的进程
                    p = Process(target=self.occupy_gpu, args=(gpu_id, lock))
                    p.start()
                    p.join()  # 等待占用过程完成，即等待2小时
                    self.gpu_idle_times.pop(gpu_id)  # 占用结束后移除空置记录

            # 更新空置记录：对不再空置的GPU移除记录
            for gpu_id in list(self.gpu_idle_times.keys()):
                if gpu_id not in free_gpus:
                    self.gpu_idle_times.pop(gpu_id)

            time.sleep(self.time_interval)

    def occupy_gpu(self, gpu_id: int, lock, a_dim=70000):
        if self.gpu_occupy_mem == 0:
            a_dim = 70000
        else:
            a_dim = int(sqrt((self.gpu_occupy_mem * 1024 * 1024 * 1024) // 8))
        
        try:
            with lock:
                if self.occupied_num.value >= self.max_gpu_number:
                    print(f"Cannot occupy GPU {gpu_id}: number limit reached.")
                    return
                if self.get_gpu_mem(gpu_id) <= self.gpu_mem_threshold:
                    a = torch.ones((a_dim, a_dim)).cuda(gpu_id)
                    self.occupied_gpus[self.occupied_num.value] = gpu_id
                    self.occupied_num.value += 1
                    print(f"Using GPU {gpu_id}, Total number of GPUs used: {self.occupied_num.value}")
                else:
                    print(f"Cannot occupy GPU {gpu_id}: insufficient memory.")
                    return

            # 占用2小时（7200秒）
            start_time = time.time()
            while time.time() - start_time < 7200:
                a = a @ a
                time.sleep(1)
            print(f"Finished using GPU {gpu_id} after 2 hours.")
            with lock:
                self.occupied_num.value -= 1

        except Exception as e:
            print(f"Exception in occupy_gpu on GPU {gpu_id}: {str(e)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Arguments for Occupy GPUs")
    parser.add_argument("--max_gpu_number", type=int, default=6, help="Max number of GPUs to occupy")
    parser.add_argument("--min_gpu_number", type=int, default=1, help="Minimal number of GPUs to execute script")
    parser.add_argument("--time_interval", type=int, default=10, help="How often to monitor GPU status, in seconds.")
    parser.add_argument("--duration_hours", type=int, default=144, help="Times to use GPU, in hours.")
    parser.add_argument(
        "--gpu_mem_threshold",
        type=int,
        default=200,
        help="GPUs with memory usage within the threshold are candidates for being occupied.(MiB)",
    )
    parser.add_argument("--gpu_occupy_mem", type=int, default=40, help="The GPU memory to occupy (GiB)")
    args = parser.parse_args()

    gpu_get = GPUGet(
        args.min_gpu_number,
        args.max_gpu_number,
        args.gpu_occupy_mem,
        args.time_interval,
        args.duration_hours,
        args.gpu_mem_threshold,
    )

    gpu_get.monitor_and_occupy()
