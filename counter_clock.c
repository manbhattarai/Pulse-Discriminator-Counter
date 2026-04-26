#include <time.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <string.h>
#include <netdb.h>

#define GPIO0_BASE_ADDRESS 0x41200000
#define GPIO1_BASE_ADDRESS 0x41210000
#define GPIO2_BASE_ADDRESS 0x41220000
#define GPIO3_BASE_ADDRESS 0x41230000
#define DISC_WIDTH_BASE_ADDRESS 0x41270000
int main(int argc, char * argv[])
{
    int fd;
    fd = open("/dev/mem",O_RDWR|O_SYNC);
    if (fd<0)
    {
        perror("Failed to open /dev/mem");
        return 1;
    }

    void *gpio0_map; //pointer to a file
    gpio0_map = mmap(NULL,32768,PROT_READ|PROT_WRITE,MAP_SHARED,fd,GPIO0_BASE_ADDRESS);
    if (gpio0_map == MAP_FAILED)
    {
        perror("Failed to map GPIO memory for bin counter");
        close(fd);
        return 1;
    }

    void *gpio1_map; //pointer to a file
    gpio1_map = mmap(NULL,32768,PROT_READ|PROT_WRITE,MAP_SHARED,fd,GPIO1_BASE_ADDRESS);
    if (gpio1_map == MAP_FAILED)
    {
        perror("Failed to map GPIO memory for threshold");
        close(fd);
        return 1;
    }

    void *gpio2_map; //pointer to a file
    gpio2_map = mmap(NULL,32768,PROT_READ|PROT_WRITE,MAP_SHARED,fd,GPIO2_BASE_ADDRESS);
    if (gpio2_map == MAP_FAILED)
    {
        perror("Failed to map GPIO memory for pulse counter");
        close(fd);
        return 1;
    }
    

    void *gpio3_map; //pointer to a file
    gpio3_map = mmap(NULL,32768,PROT_READ|PROT_WRITE,MAP_SHARED,fd,GPIO3_BASE_ADDRESS);
    if (gpio3_map == MAP_FAILED)
    {
        perror("Failed to map GPIO memory for yag signal");
        close(fd);
        return 1;
    }

    void *disc_width_map;
    disc_width_map = mmap(NULL,32768,PROT_READ|PROT_WRITE,MAP_SHARED,fd,DISC_WIDTH_BASE_ADDRESS);
    if(disc_width_map == MAP_FAILED)
    {
        perror("Failed to map GPIO memory to disc width signal.");
	close(fd);
	return 1;
    }



    volatile unsigned int *gpio0_data; //pointer to bin counter output
    volatile unsigned int *gpio1_data; //pointer to threshold value
    volatile unsigned int *gpio2_data; //pointer to pulse count value
    volatile unsigned int *gpio3_data; //pointer to yag value
    volatile unsigned int *disc_width_data; //pointer to discriminator output width  value


    //set the disc_out value here
    unsigned int disc_width;
    disc_width_data = (volatile unsigned int *)disc_width_map;
    disc_width = atoi(argv[4]);
    *disc_width_data = disc_width;
    //set the value of threshold
    unsigned int threshold;
    gpio1_data = (volatile unsigned int *)gpio1_map;
    threshold = atoi(argv[1]);
    *gpio1_data = threshold;

    printf("Threshold set to %d\n",threshold);
    //printf("Sleeping for 1 s\n");
    //sleep(1);
    //set and read value of bn counter and pulse counts respectively
    int bin_start,bin_end,bin_current;
    bin_start= atoi(argv[2]);
    bin_end= atoi(argv[3]);
    bin_current = bin_start;
    unsigned int temp_data[5000];
    printf("Start: %d\n End: %d \n",bin_start,bin_end);

    gpio0_data = (volatile unsigned int *)gpio0_map;
    gpio2_data = (volatile unsigned int *)gpio2_map;
    gpio3_data = (volatile unsigned int *)gpio3_map;


    //see if the yag has turned off
    unsigned int yag = 0;
    unsigned int yag_prev = 0;
    while(!((yag == 0) && (yag_prev == 1)))
    {
	yag_prev = yag;
	yag = *gpio3_data & 0x1;
    }
    printf("Yag = %u, prev_yag = %u \n",yag,yag_prev);
    printf("Pass yag test.\n");
    clock_t start,end;
    double time_taken;
    start = clock();

    while (bin_current <bin_end)
    {
	*gpio0_data = bin_current;
	temp_data[bin_current] = *gpio2_data;
	bin_current++;
    }

    printf("Displaying data\n");
    bin_current = bin_start;
    int sum = 0;
    while(bin_current <bin_end)
    {
	//printf("Bin number %d: %d\n",bin_current ,temp_data[bin_current]);	

        sum = sum + temp_data[bin_current];
	bin_current++;
    }
    end = clock();
    time_taken  = ((double)(end-start)/CLOCKS_PER_SEC);
    printf("Sum of counts : %d\n",sum);
    double count_rate;
    count_rate = sum/10.0/(bin_end-bin_start);
    printf("Count rate : %f MHz\n",count_rate);
    printf("Time taken : %f ms\n",time_taken*1000.0);

#if 0
    //setup server here
    char server_message[32];
    int server_socket;
    int opt =1;
    if ((server_socket = socket(AF_INET,SOCK_STREAM,0)) == 0)
    {
	perror("Socket creation failed"); exit(EXIT_FAILURE);
    }

    //attach socket to a port forcefully
    if(setsockopt(server_socket,SOL_SOCKET,SO_REUSEADDR|SO_REUSEPORT,&opt,sizeof(opt)))
    {
	perror("Setsockopt failed");exit(EXIT_FAILURE);
    }

    //define server address
    struct sockaddr_in server_address;
    int addrlen = sizeof(server_address);
    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(9002);
    server_address.sin_addr.s_addr = INADDR_ANY;

    //bind the socket to the specified IP and port
    if(bind(server_socket,(struct  sockaddr *)&server_address,sizeof(server_address)) < 0 )
    {
	perror("Bind failed");exit(EXIT_FAILURE);
    }
    //listen to incoming connection
    if(listen(server_socket,5)<0)
    {
	perror("Listen failed");exit(EXIT_FAILURE);
    }


    int client_socket;
    char client_message[32];
    int bytes_received;
    if((client_socket = accept(server_socket,(struct sockaddr *)&server_address, (socklen_t*)&addrlen))<0)
    {
	perror("Accept failed");exit(EXIT_FAILURE);
    }
    int N;
    bytes_received = recv(client_socket,client_message,sizeof(client_message),0);
    /*
    char actual_client_message[bytes_received];
        for(int count = 0;count<bytes_received;count++)
        {
            actual_client_message[count] = client_message[count];
        }
    N = atoi(actual_client_message);
    printf("number of samples : %d\n",N);
    */

    strcpy(server_message,"Acknowlegded");
    send(client_socket,server_message,strlen(server_message),0);

    printf("Transferring data\n");
    /*
    while(bin_current  < bin_end)
    {
	bytes_received = recv(client_socket,client_message,sizeof(client_message),0);
	//printf("%d, ",temp_data[count]);
	sprintf(val_str, "%d", temp_data[bin_current]);
    	strcpy(server_message,val_str);
    	send(client_socket,server_message,strlen(server_message),0);

        bin_current++;
    }
    */
    printf("Array size : %u\n",sizeof(temp_data));
    if(send(client_socket,temp_data,sizeof(temp_data),0)<0)
    {
        perror("Error sending data.");
        exit(1);
    }
    printf("Transfer complete\n");
#endif

    munmap(gpio0_map,32768);
    munmap(gpio1_map,32768);
    munmap(gpio2_map,32768);
    munmap(gpio3_map,32768);
    munmap(disc_width_map,32768);
    close(fd);
    //close(client_socket);
    //close(server_socket);
    return 0;
}
