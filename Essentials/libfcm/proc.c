#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <unistd.h>

typedef struct {
    pid_t *list;
    uint64_t count;
} pid_list_t;

pid_list_t getChilds(pid_t ppid) {
    pid_list_t list;
    size_t length;
    struct kinfo_proc *procs = NULL;
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };

    if (sysctl(mib, 4, NULL, &length, NULL, 0) == -1) {
        perror("sysctl (size)");
        exit(EXIT_FAILURE);
    }

    procs = malloc(length);
    if (procs == NULL) {
        perror("malloc");
        exit(EXIT_FAILURE);
    }

    if (sysctl(mib, 4, procs, &length, NULL, 0) == -1) {
        perror("sysctl (data)");
        free(procs);
        exit(EXIT_FAILURE);
    }

    int proc_count = length / sizeof(struct kinfo_proc);

    uint64_t child_count = 0;
    for (int i = 0; i < proc_count; i++) {
        if (procs[i].kp_eproc.e_ppid == ppid) {
            child_count++;
        }
    }

    list.list = calloc(child_count, sizeof(pid_t));
    list.count = child_count;

    int j = 0;
    for (int i = 0; i < proc_count; i++) {
        if (procs[i].kp_eproc.e_ppid == ppid) {
            list.list[j++] = procs[i].kp_proc.p_pid;
        }
    }

    free(procs);
    return list;
}

void killallchilds(void) {
    pid_list_t list = getChilds(getpid());

    for(uint64_t i = 0; i < list.count; i++) {
        if(list.list[i] != getpid()) {
            kill(list.list[i], SIGKILL);
        }
    }

    free(list.list);
}
