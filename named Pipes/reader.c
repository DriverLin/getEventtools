#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <limits.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>
#include <stdio.h>

int main()
{
    const char *fifo_name = "/data/data/com.termux/files/usr/tmp/namedFifo";
    int pipe_fd = -1;
    int res = 0;
    int open_mode = O_RDONLY;
    char buffer[PIPE_BUF + 1];
    printf("进程[%d]只读\n", getpid());
    printf("等待写入进程\n");
    pipe_fd = open(fifo_name, open_mode);
    printf("写入进程已启动\n");
    while (1)
    {
        memset(buffer, '\0', sizeof(buffer));
        res = read(pipe_fd, buffer, PIPE_BUF);
        if (res != 0)
        {
            printf("pipe >> %s\n", buffer);
        }
        else
        {
            break;
        }
    }
    close(pipe_fd);
    exit(EXIT_SUCCESS);
}