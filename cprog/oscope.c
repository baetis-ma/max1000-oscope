#include <errno.h>

#include <fcntl.h> 
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <stdio.h>
#include "./set_interface_attribs.h"
#include "./kbhit.h"

void changemode(int);
int  kbhit(void);
//these do not need predefinition of syncing
int r30=0x180, r50=0x400, r51=0x8002, r52=0x0001, r53=0x0010, r90=0x8100, r91=0x0040, off=1;
//these must be known 
int samples=500, chcnt=2, trigger=1, trig_ch = 0, trig_pol = 1, trigoff, trig_mode;
float ftime = 1.0, foff = 0.1;

void menu(int fd)
{
   char temp, tout[12];
   float ftemp, ftemp1;
   if(kbhit() || temp == 'i'){
      temp=getchar(); 
      if (temp == 'h'){
         fprintf(stderr, "x - timebase\n");
         fprintf(stderr, "y - channel volt offsets toggle\n");
         fprintf(stderr, "c - number of chcnt\n");
         fprintf(stderr, "S - number of samples\n");
         fprintf(stderr, "t - toggle trigger off/+edge/-edge\n");
         fprintf(stderr, "C - toggle trigger channel\n");
         fprintf(stderr, "p - pwm rate and percent\n");
         fprintf(stderr, "s - sinewave frequency\n");
         fprintf(stderr, "u - update rate\n");
         fprintf(stderr, "o - trigger offset in samples\n");
         fprintf(stderr, "r - default\n");
         fprintf(stderr, "h - this message\n");
      }
      if (temp == 'p'){
         fprintf(stderr, "enter pwm rate (ms) and fraction active : ");
         scanf("%f %f", &ftemp, &ftemp1);
         fprintf(stderr, "\n");
         if (ftemp < .005 || ftemp > 1000 || ftemp1 <0 || ftemp1 > 1) fprintf(stderr, "not valid samples\n"); 
         else { r90 = -1 + (int)((200000/128)*ftemp);
                r91 = (int)(ftemp1*r90/2);
fprintf(stderr,"r90 = 0x%04x r91 = 0x%04x\n", r90, r91);
                sprintf(tout, "w 90 %04x", r90);    
                tout[strlen(tout)] = '\x0d';
                tout[strlen(tout)] = '\0';
                write(fd, tout, strlen(tout));
                tcdrain(fd);
                sprintf(tout, "w 91 %04x", r91);    
                tout[strlen(tout)] = '\x0d';
                tout[strlen(tout)] = '\0';
           fprintf(stderr, "pwm rate = %3.3f msec  %5.3f duty cycle\n", ftemp, ftemp1);
                write(fd, tout, strlen(tout));
                tcdrain(fd);
         }
      }
      if (temp == 'u'){
         fprintf(stderr, "enter screen update rate in seconds : ");
         scanf("%f", &ftemp);
         fprintf(stderr, "\n");
         if (ftemp < .1 || ftemp > 10) fprintf(stderr, "not valid num\n"); 
         else { r30 = (int)(ftemp*0x300);
                sprintf(tout, "w 30 %04x", r30);    
                tout[strlen(tout)] = '\x0d';
                tout[strlen(tout)] = '\0';
                fprintf(stderr, "%s   update rate %3.2fsec\n", tout, ftemp);
                write(fd, tout, strlen(tout));
                tcdrain(fd);
         }
      }
      if (temp == 'y'){
         if (off == 1) off = 0; else off = 1;
      }
      if (temp == 'C'){
         if (trig_ch < chcnt-1) trig_ch = trig_ch + 1; else trig_ch = 0;
         r51 = trigger*0x8000 + 0x2000 * trig_ch + 0x1000 * trig_pol + chcnt;
         sprintf(tout, "w 51 %04x", r51);    
         tout[strlen(tout)] = '\x0d';
         tout[strlen(tout)] = '\0';
         write(fd, tout, strlen(tout));
         fprintf(stderr, "trigger channel %d\n", trig_ch+1);
         tcdrain(fd);
      }
      if (temp == 't'){
         trig_mode = trigger + trig_pol;
         if (trig_mode < 2) trig_mode = trig_mode + 1; else trig_mode = 0;
         if(trig_mode == 0) {trigger = 0; trig_pol = 0;}
         if(trig_mode == 1) {trigger = 1; trig_pol = 0;}
         if(trig_mode == 2) {trigger = 1; trig_pol = 1;}
         r51 = trigger*0x8000 + 0x2000 * trig_ch + 0x1000 * trig_pol + chcnt;
         sprintf(tout, "w 51 %04x", r51);    
         tout[strlen(tout)] = '\x0d';
         tout[strlen(tout)] = '\0';
         write(fd, tout, strlen(tout));
         if(trig_mode==0)fprintf(stderr, "trigger off\n");
         if(trig_mode==1)fprintf(stderr, "falling edge trigger\n");
         if(trig_mode==2)fprintf(stderr, "rising edge trigger\n");
         tcdrain(fd);
      }
      if (temp == 's'){
         fprintf(stderr, "enter sin frequency in hz : ");
         scanf("%f", &ftemp);
         fprintf(stderr, "\n");
         if (ftemp < 1 || ftemp > 25000) fprintf(stderr, "not valid freq\n"); 
         else { r90 = 0x8000 + (int)(0.70*ftemp);
                sprintf(tout, "w 90 %04x", r90);    
                tout[strlen(tout)] = '\x0d';
                tout[strlen(tout)] = '\0';
                write(fd, tout, strlen(tout));
                fprintf(stderr, "sine freq = %d Hz\n", (int)ftemp);
                tcdrain(fd);
         }
      }
      if (temp == 'S'){
         fprintf(stderr, "enter number of samples (1-1000) : ");
         scanf("%d", &samples);
         if(samples<1 || samples >8000)samples = 500;
         fprintf(stderr, "samples=%d\n",samples);
      }
      if (temp == 'c'){
         fprintf(stderr, "enter number of chcnt (1-4) : ");
         scanf("%d", &chcnt);
         if (chcnt <1 || chcnt >4) chcnt = 1;
         fprintf(stderr, "channels = %d\n", chcnt);
      }
      if (temp == 'x'){
         fprintf(stderr, "enter timebase sweep in msec : ");
         scanf("%f", &ftime);
         fprintf(stderr, "%5.2f\n", ftime);
      }
      if (temp == 'o'){
         fprintf(stderr, "enter trigger offset as part fs (0-1): ");
         scanf("%f", &foff);
         //if (foff < 0 || foff > 1) {foff = 0.1; fprintf(stderr, "not valid (.1)\n"); }
         fprintf(stderr, "trig delay = %3.2f\n", foff);
      }
      if( temp == 'S' || temp == 'x' || temp == 'c' || temp == 'o'){ 
                r50 = 2 * samples * chcnt;
                r51 = trigger*0x8000 + 0x2000 * trig_ch + 0x1000 * trig_pol + chcnt;
                r52 = (int)(1000*ftime/(chcnt*samples));
                r53 = (int) chcnt * (foff * samples);
                  //fprintf(stderr, "r53 = 0x%04x  %d\n",r53,r53);
                  if (r53 < 0)r53 = 0xffff + r53;
                  //fprintf(stderr, "r53 = 0x%04x  %d\n",r53,r53);
                //total bytes in packet
                sprintf(tout, "w 50 %04x", r50);    
                tout[strlen(tout)] = '\x0d';
                tout[strlen(tout)] = '\0';
                write(fd, tout, strlen(tout));
                fprintf(stderr, "%s\n", tout);
                //trigger and channels
                sprintf(tout, "w 51 %04x", r51);    
                tout[strlen(tout)] = '\x0d';
                tout[strlen(tout)] = '\0';
                write(fd, tout, strlen(tout));
                fprintf(stderr, "%s\n", tout);
                //sample rate
                if (r52 < 1) r52 = 1;
                sprintf(tout, "w 52 %04x", r52);    
                tout[strlen(tout)] = '\x0d';
                tout[strlen(tout)] = '\0';
                write(fd, tout, strlen(tout));
                fprintf(stderr, "%s\n", tout);
                //trig delay
                sprintf(tout, "w 53 %04x", r53);    
                tout[strlen(tout)] = '\x0d';
                tout[strlen(tout)] = '\0';
                write(fd, tout, strlen(tout));
                fprintf(stderr, "%s\n", tout);
                if(trigger == 0)fprintf(stderr, "samples = %d channels = %d   timebase = %2.2fms   trig off\n", 
                             samples, chcnt, ftime);
                fprintf(stderr, "samples = %d channels = %d   timebase = %2.2fms   trig on delay = %2.2fms\n", 
                             samples, chcnt, ftime, foff * ftime);
                tcdrain(fd);
      }
   }
}

void main() 
{ 
   
    char ch[128], temp;
    char buf [128];
    int cntstart = 0,start, n, cnt = 0, c=0;
    char *portname = "/dev/ttyUSB0" ;
    //char *portname = "/dev/ttyUSB1";
    float volt,time,realxaxis;
    int length, cntx, strobe=0, rlen, addr,volttemp, volti[4], trigger, chcnt, timeus;
    unsigned char byte[1];
    int header = 0x20;

    int fd = open (portname, O_RDWR | O_NOCTTY | O_SYNC);
    if (fd < 0) { fprintf (stderr, "error %d opening %s: %s", errno, portname, strerror (errno)); return; }

    set_interface_attribs (fd, B500000, 0);  // speed to 500,000 bps, 8n1 np 
    set_blocking (fd, 0);                // set no blocking

    changemode(1); 
    printf("set terminal wxt noraise background rgb \'dark-olivegreen\'\n");
    printf("set autoscale\n");
    printf("set title \"Oscilliscope\"\n");
    printf("set xlabel \"time (ms)\"\n");
    printf("set grid ytics lt 0 lw 0.5 lc rgb \"yellow\"\n");
    printf("set grid xtics lt 0 lw 0.5 lc rgb \"yellow\"\n");
    printf("array xa[4100]\n");
    printf("array y1a[4100]\n");
    printf("array y2a[4100]\n");
    printf("array y3a[4100]\n");
    printf("array y4a[4100]\n");

    while(1) {
        menu(fd);
        read(fd,byte,1);
        cnt = cnt + 1;
     //if(cnt<100)printf("%4d  byte[0]=%c  cnt=%d  strobe=%d\n",cnt, byte[0],cnt, strobe);

     if (byte[0] == 'o' && cnt != 3)  {strobe = 0; cnt = 0; }
     if (byte[0] == 's' && cnt == 1) strobe = 1; 
     if (byte[0] == 'c' && cnt == 2) strobe = 2;
     if (byte[0] == 'p' && cnt == 4) strobe = 3; 
     if (byte[0] == 'e' && cnt == 5 && strobe == 3) {cnt = 0; strobe = 4; cntstart = 0; }
     if (strobe == 4) {
        while(strobe == 4 && read(fd,byte,1)!= 0)  {
           menu(fd);
           cnt = cnt + 1;
           if (cnt == 1) {trigger = byte[0]/128; 
                          trig_ch = (byte[0]%128)/32; 
                          trig_pol = (byte[0]%32)/16; 
                          chcnt = byte[0]%8; }
           if (cnt == 2) length = 256*byte[0];
           if (cnt == 3) length = length + byte[0];
           if (cnt == 4) timeus = 256*byte[0];
           if (cnt == 5) timeus = timeus + byte[0];
           if (cnt == 6) trigoff = 256*byte[0];
           if (cnt == 7) trigoff = trigoff + byte[0];
           //if (cnt == 7) fprintf(stderr,"triggeroffset = %d\n", trigoff);
           if(cnt==header){printf("set yrange[-0.5:%d]\n",4+off*4*(chcnt-1));
              realxaxis = 0.001*(float)chcnt*timeus*samples;  
              printf("set xrange[0:%f]\n",0.001*(float)chcnt*timeus*samples);  
              printf("unset label 1\n");  
              if (trigger == 1 & foff < 0) 
                   printf("set label 1 \"<-\" font \",12\" at %f,-.75 center tc rgb \'red\'\n",0.00);  
              if (trigger == 1 & foff > 1) 
                   printf("set label 1 \"->\" font \",12\" at %f,-.75 center tc rgb \'red\'\n",realxaxis);  
              if (trigger == 1 & foff >= 0 & foff <= 1) 
                   printf("set label 1 \"*\" font \",20\" at %f,-.75 center tc rgb \'red\'\n",foff*realxaxis);  
              printf("set xlabel \"time (ms) - %dus/ samp %d samples/channel\"\n",
                                       chcnt*timeus,samples);
              printf("set style line 1 lw 1.5 pt 7 ps .5 lc rgb \'salmon\'\n");
              printf("set style line 2 lw 1.5 pt 7 ps .5 lc rgb \'sandybrown\'\n");
              printf("set style line 3 lw 1.5 pt 7 ps .5 lc rgb \'light-red\'\n");
              printf("set style line 4 lw 1.5 pt 7 ps .5 lc rgb \'yellow\'\n");
              printf("array xa[4100]\n");
              printf("array y1a[4100]\n"); printf("array y2a[4100]\n");
              printf("array y3a[4100]\n"); printf("array y4a[4100]\n"); 
           }
           volttemp = 0;
           if(cnt>header) { if(byte[0] / 0x80 == 1) volttemp = byte[0]%0x80; else  { volti[byte[0]/32] = volttemp + 128 * (byte[0]%32); }
              if(chcnt == 1 && byte[0]/32 == 0){
                 printf("xa[%d]  = %6.3f; ", 1+(cnt-header)/2, 0.001*timeus*(cnt-header)/2);
                 printf("y1a[%d] = %6.3f\n", 1+(cnt-header)/2, 3.3/4096*(float)volti[0]); 
               }
               if(chcnt == 2 && byte[0]/32 == 1){
                  printf("xa[%d]  = %6.3f; ", 1+(cnt-header)/4, 0.001*timeus*(cnt-header)/2);
                  printf("y1a[%d] = %6.3f; ", 1+(cnt-header)/4, 0*off+3.3/4096*(float)volti[0]);
                  printf("y2a[%d] = %6.3f\n", 1+(cnt-header)/4, 4*off+3.3/4096*(float)volti[1]); 
               }
               if(chcnt == 3 && byte[0]/32 == 2){
                  printf("xa[%d]  = %6.3f; ", 1+(cnt-header)/6, 0.001*timeus*(cnt-header)/2);
                  printf("y1a[%d] = %6.3f; ", 1+(cnt-header)/6, 0*off+3.3/4096*(float)volti[0]);
                  printf("y2a[%d] = %6.3f; ", 1+(cnt-header)/6, 4*off+3.3/4096*(float)volti[1]);
                  printf("y3a[%d] = %6.3f\n", 1+(cnt-header)/6, 8*off+3.3/4096*(float)volti[2]);
               }
               if(chcnt == 4 && byte[0]/32 == 3){
                  printf("xa[%d]  = %6.3f; ", 1+(cnt-header)/8, 0.001*timeus*(cnt-header)/2);
                  printf("y1a[%d] = %6.3f; ", 1+(cnt-header)/8, 0*off+3.3/4096*(float)volti[0]);
                  printf("y2a[%d] = %6.3f; ", 1+(cnt-header)/8, 4*off+3.3/4096*(float)volti[1]);
                  printf("y3a[%d] = %6.3f; ", 1+(cnt-header)/8, 8*off+3.3/4096*(float)volti[2]); 
                  printf("y4a[%d] = %6.3f\n", 1+(cnt-header)/8,12*off+3.3/4096*(float)volti[3]);
              }
           }
        }
        //if ((cnt-header) == length ) { 
        if (1 ) { 
           if(chcnt == 1) {
              printf("plot xa u 2:(y1a[$1]) title 'ch0' w linespoints ls 1\n");
           }
           if(chcnt == 2) {
              printf("plot xa u 2:(y1a[$1]) title 'ch0' w linespoints ls 1, \\\n");
              printf(" xa u 2:(y2a[$1]) title 'ch1' w linespoints ls 2\n");
           }
           if(chcnt == 3) {
              printf("plot xa u 2:(y1a[$1]) title 'ch0' w linespoints ls 1, \\\n");
              printf(" xa u 2:(y2a[$1]) title 'ch1' w linespoints ls 2, \\\n");
              printf(" xa u 2:(y3a[$1]) title 'ch2' w linespoints ls 3\n");
           }
           if(chcnt == 4) {
              printf("plot xa u 2:(y1a[$1]) title 'ch0' w linespoints ls 1, \\\n");
              printf(" xa u 2:(y2a[$1]) title 'ch1' w linespoints ls 2, \\\n");
              printf(" xa u 2:(y3a[$1]) title 'ch2' w linespoints ls 3, \\\n");
              printf(" xa u 2:(y4a[$1]) title 'ch3' w linespoints ls 4\n");
           }
           cnt = 0; strobe = 0;
        }
        fflush(stdout);
     }
  }
  changemode(0);
}
