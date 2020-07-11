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
    const char *fifo_name = "/data/data/com.termux/files/usr/tmp/namedFifo"; //fifo文件
    int pipe_fd = -1;                                                        //管道指针
    const int open_mode = O_WRONLY;                                          //打开方式 只写
    char buffer[PIPE_BUF + 1];
    if (access(fifo_name, F_OK) == -1) //文件不存在 则创建
        if (mkfifo(fifo_name, 0777) != 0)
        {
            printf("！=0 错误 exit\n");
            exit(EXIT_FAILURE);
        }
    printf("进程[%d]只写\n", getpid());
    printf("等待读取进程\n");
    pipe_fd = open(fifo_name, open_mode);
    printf("读取进程已启动\n");
    do
    {
        printf("pipe << ");
        memset(buffer, '\0', sizeof(buffer));
        scanf("%s", buffer);
        write(pipe_fd, buffer, PIPE_BUF);
    } while (strcmp(buffer, "end\0"));
    close(pipe_fd);
    exit(EXIT_SUCCESS);
}