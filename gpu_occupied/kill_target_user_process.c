#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <signal.h>
#include <pwd.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <PID>\n", argv[0]);
        return 1;
    }

    int pid = atoi(argv[1]);
    struct stat statbuf;
    char proc_path[256];
    snprintf(proc_path, sizeof(proc_path), "/proc/%d", pid);

    // 检查目标进程是否存在
    if (stat(proc_path, &statbuf) == -1) {
        perror("Error: Process does not exist");
        return 1;
    }

    // 检查进程的所有者是否是特定用户，例如 "targetuser"
    struct passwd *pwd = getpwnam("targetuser");  // 将 "targetuser" 替换为目标用户名
    if (!pwd) {
        fprintf(stderr, "Error: User 'targetuser' not found\n");
        return 1;
    }

    if (statbuf.st_uid != pwd->pw_uid) {
        fprintf(stderr, "Error: Process does not belong to target user 'targetuser'\n");
        return 1;
    }

    // 终止该进程
    if (kill(pid, SIGKILL) == -1) {
        perror("Error: Failed to kill process");
        return 1;
    }

    printf("Process %d owned by 'targetuser' killed successfully.\n", pid);
    return 0;
}
