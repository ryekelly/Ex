/* MATLABUDP.C
 *
 *	MATLABUDP.c contains a few c-routines
 *	to be called from MATLAB so that the ex_control and ex_display
 *  machines can chat via ethernet and the UDP/IP protocols.
 *
 *  This is modified from matlabUDP.c written by Ben Heasly in Josh Gold's
 *  lab at UPenn. Ryan Kelly changed it to work with Windows XP in May 2012.
 * 
 *  Compile with something like this:
 *  mex matlabUDP.c 'C:\Program Files\MATLAB\R2010b\sys\lcc\lib\wsock32.lib'
 *  [need to use Lcc, not watcom]
 */

#include "matlabUDP.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    char *command=NULL;
    int buf_len;
            char local[16];
            char remote[16];
        int dims[2],i;
        unsigned short *outPtr;
    WSADATA WSA_Data;
        
    // If no arguments given, print usage string
    if(nrhs < 1) {
        mexPrintf("matlabUDP usage:\n socketIsOpen = matlabUDP('open', (string)localIP, (string)remoteIP, (int)port);%% should return small int\n matlabUDP('send', (string)message);\n messageIsAvailable = matlabUDP('check');\n message = matlabUDP('receive');\n socketIsOpen = matlabUDP('close');%% should return -1\n");
        return;
    }
    
    // First argument is command string... get and convert to char *
    if(mxGetM(prhs[0]) == 1 && mxGetN(prhs[0]) >= 1 && mxIsChar(prhs[0])) {
        buf_len =  mxGetN(prhs[0]) + 1;
        command = mxCalloc(buf_len, sizeof(char));
        if(mxGetString(prhs[0], command, buf_len))
            mexWarnMsgTxt("matlabUDP: Not enough heap space. String (command) is truncated.");
    } else {
        mexErrMsgTxt("matlabUDP: First argument should be a string (command).");
    }
    
    // case on command string...
    if(!strncmp(command, "open", 3)) {
        // done with command
        mxFree(command);
       
        if (WSAStartup(0x101, &w)) {
            mexErrMsgTxt("Failed.");
        }
        
        // register exit routine to free socket
        if(mexAtExit(mat_UDP_close) != 0 ) {
            mat_UDP_close();
            mexErrMsgTxt("matlabUDP: failed to register exit routine, mat_UDP_close.");
        }
        
        // only open a fresh socket if
        //  PORT arg is a number, and
        //  IP addr args are short strings e.g. "111.222.333.444"
        if(nrhs==4 && mxIsNumeric(prhs[3])
        && mxIsChar(prhs[2]) && mxGetN(prhs[2])<=15
        && mxIsChar(prhs[1]) && mxGetN(prhs[1])<=15){

            // close old socket?
//            if(mat_UDP_sockfd>=0) {
   //             mat_UDP_close();
//            }
            //format args for socket opener function
            mxGetString(prhs[1],local,16);
            mxGetString(prhs[2],remote,16);

            //openerup
            mexPrintf("matlabUDP opening socket\n");
            mat_UDP_open(local, remote, (int)mxGetScalar(prhs[3]));            
        }
        // build me a return value worthy of MATLAB
        if(!(plhs[0] = mxCreateDoubleScalar((double)mat_UDP_sockfd)))
            mexErrMsgTxt("matlabUDP: mxCreateNumericArray failed.");
    } else if(!strncmp(command, "receive", 3)) {
        // done with command
        mxFree(command);
        
        dims[0] = 1;
        
        if(nlhs<=1){
            if(mat_UDP_sockfd<0){
                // socket closed so zero bytes are read
                i = 0;
            } else {
                // read new bytes from socket
                mat_UDP_read(mat_UDP_messBuff, MAX_NUM_BYTES);//sets mat_UDP_numBytes
                i = mat_UDP_numBytes;
            }

            // always provide at least an empty return value
            dims[1] = i;
            if(!(plhs[0] = mxCreateCharArray(2, dims)))
                mexErrMsgTxt("matlabUDP: mxCreateCharArray failed.");
            
            // fill in report with any new bytes
            outPtr = (unsigned short *) mxGetData(plhs[0]);
            for(i--; i>=0; i--){
                *(outPtr + i) = mat_UDP_messBuff[i];
            }
        }
    } else if(!strncmp(command, "send", 3)) {
        // done with command
        mxFree(command);
        
        if(mat_UDP_sockfd<0){
            // warn that no message was not sent
            mexWarnMsgTxt("matlabUDP: Message not sent.  No socket is open.");
        } else {
            // only send message if message arg is a 1-by-N char array
            if(nrhs==2 && mxIsChar(prhs[1]) && mxGetM(prhs[1])==1 && mxGetN(prhs[1])>0){
                // format ye string and send forth
                mxGetString(prhs[1],mat_UDP_messBuff,mxGetN(prhs[1])+1);
                mat_UDP_send(mat_UDP_messBuff, mxGetN(prhs[1]));
            }else{
                // warn that no message was not sent
                mexWarnMsgTxt("matlabUDP: Message not sent.  Must be 1-by-N char array.");
            }
        }        
    } else if(!strncmp(command, "check", 3)) {        
        // done with command
        mxFree(command);
        
        // always provide a return value
        // if socket is closed, && will short-circuit and skip the actual socket check
        if(!(plhs[0] = mxCreateDoubleScalar( (double) (mat_UDP_sockfd>=0) && mat_UDP_check() )))
            mexErrMsgTxt("matlabUDP: mxCreateNumericArray failed.");
        
        
    } else if(!strncmp(command, "close", 3)) {       
        // done with command
        mxFree(command);

        // only try to close if socket is open
        if(mat_UDP_sockfd >= 0)
            mat_UDP_close();
        
        // always return socket index
        if(nlhs==1){
            if(!(plhs[0] = mxCreateDoubleScalar((double)mat_UDP_sockfd)))
                mexErrMsgTxt("matlabUDP: mxCreateNumericArray failed.");
        }
    } else {
        // done with command
        mxFree(command);
        mexWarnMsgTxt("matlabUDP: Unknown command option");
    }
}

//initialize UDP socket
void mat_UDP_open (char localIP[], char remoteIP[], int port){
    int a1, a2, a3, a4, b1, b2, b3, b4;
    char errMsg[50];
    
    sscanf(localIP, "%d.%d.%d.%d", &a1, &a2, &a3, &a4);
    sscanf(remoteIP, "%d.%d.%d.%d", &b1, &b2, &b3, &b4);
    if ((mat_UDP_sockfd=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == INVALID_SOCKET) {
        sprintf(errMsg, "Couldn't create UDP socket: %i", WSAGetLastError());
        mexErrMsgTxt(errMsg);
    }

    memset((void *)&mat_UDP_REMOTE_addr, '\0', sizeof(struct sockaddr_in));
    mat_UDP_REMOTE_addr.sin_family = AF_INET;	// host byte order
    mat_UDP_REMOTE_addr.sin_port = htons(port);	// short, network byte order
    mat_UDP_REMOTE_addr.sin_addr.S_un.S_un_b.s_b1 = (unsigned char)b1;
    mat_UDP_REMOTE_addr.sin_addr.S_un.S_un_b.s_b2 = (unsigned char)b2;
    mat_UDP_REMOTE_addr.sin_addr.S_un.S_un_b.s_b3 = (unsigned char)b3;
    mat_UDP_REMOTE_addr.sin_addr.S_un.S_un_b.s_b4 = (unsigned char)b4;

    memset((void *)&mat_UDP_LOCAL_addr, '\0', sizeof(struct sockaddr_in));
    mat_UDP_LOCAL_addr.sin_family = AF_INET;         // host byte order
    mat_UDP_LOCAL_addr.sin_port = htons(port);     // short, network byte order
    mat_UDP_LOCAL_addr.sin_addr.S_un.S_un_b.s_b1 = (unsigned char)a1;
    mat_UDP_LOCAL_addr.sin_addr.S_un.S_un_b.s_b2 = (unsigned char)a2;
    mat_UDP_LOCAL_addr.sin_addr.S_un.S_un_b.s_b3 = (unsigned char)a3;
    mat_UDP_LOCAL_addr.sin_addr.S_un.S_un_b.s_b4 = (unsigned char)a4;

    //mexPrintf("localIP = <%s>\n",inet_ntoa(mat_UDP_LOCAL_addr.sin_addr));
    //mexPrintf("remoteIP = <%s>\n",inet_ntoa(mat_UDP_REMOTE_addr.sin_addr));
    //mexPrintf("ports = <%i>,<%i>\n",mat_UDP_LOCAL_addr.sin_port,mat_UDP_REMOTE_addr.sin_port  );    
    //mexPrintf("sockFD = %i\n",mat_UDP_sockfd);
    
    if (bind(mat_UDP_sockfd, (struct sockaddr *)&mat_UDP_LOCAL_addr, sizeof(struct sockaddr_in)) == -1){
        mexErrMsgTxt("Couldn't bind socket.  Maybe invalid local address.");
    }
}

//send a string to MATLAB
void mat_UDP_send (char mBuff[], int mLen){
    if ((mLen=sendto(mat_UDP_sockfd, mBuff, mLen, 0,
    (struct sockaddr *)&mat_UDP_REMOTE_addr, sizeof(struct sockaddr))) == -1)
        mexWarnMsgTxt("Couldn't send string.  Are computers connected??");
}

//is a return message available?
int mat_UDP_check (void){
    static struct timeval timout;
    static fd_set readfds;
    FD_ZERO(&readfds);
    FD_SET(mat_UDP_sockfd,&readfds);
    select(mat_UDP_sockfd+1,&readfds,NULL,NULL,&timout);
    return(FD_ISSET(mat_UDP_sockfd,&readfds));
}

//read any available message
void mat_UDP_read (char mBuff[], int messUpToLen){    
    if ((mat_UDP_numBytes=recvfrom(mat_UDP_sockfd,mBuff, messUpToLen, 0,
    (struct sockaddr *)&mat_UDP_REMOTE_addr, &mat_UDP_addr_len)) <0 )
        mat_UDP_numBytes=0;   
}

//cleanup UDP socket
void mat_UDP_close (void){
    if(mat_UDP_sockfd>=0){
        mexPrintf("matlabUDP closing socket\n");
        closesocket(mat_UDP_sockfd);
        WSACleanup();
//        mat_UDP_sockfd=-1;
    }
}
