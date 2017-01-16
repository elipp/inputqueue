//
//  AppDelegate.m

#import "AppDelegate.h"
#import "record.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

static void HandleInputBuffer (
                        void                                *aqData,             // 1
                        AudioQueueRef                       inAQ,                // 2
                        AudioQueueBufferRef                 inBuffer,            // 3
                        const AudioTimeStamp                *inStartTime,        // 4
                        UInt32                              inNumPackets,        // 5
                        const AudioStreamPacketDescription  *inPacketDesc        // 6
) {
    
    struct AQRecorderState *pAqData = (struct AQRecorderState *) aqData;               // 1
    
    if (inNumPackets == 0 && pAqData->mDataFormat.mBytesPerPacket != 0) {
        inNumPackets =
        inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    }
    ALog("hi from HandleInputBuffer!\n");
    if (pAqData->mIsRunning == 0)
        return;
    
    AudioQueueEnqueueBuffer(pAqData->mQueue, inBuffer, 0, NULL);
    
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    struct AQRecorderState S;
    
#define PRINT_R do{\
ALog("r = %d\n", r);\
}while(0)
    
    AudioStreamBasicDescription *fmt = &S.mDataFormat;
    
    fmt->mFormatID         = kAudioFormatLinearPCM; 
    fmt->mSampleRate       = 44100.0;
    fmt->mChannelsPerFrame = 1;
    fmt->mBitsPerChannel   = 16;
    fmt->mBytesPerFrame    = fmt->mChannelsPerFrame * sizeof(short);
    fmt->mFramesPerPacket  = 1;
    fmt->mBytesPerPacket   = fmt->mBytesPerFrame * fmt->mFramesPerPacket;
    fmt->mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kLinearPCMFormatFlagIsPacked;
    fmt->mReserved = 0;
    
    OSStatus r = 0;
    
    r = AudioQueueNewInput(&S.mDataFormat, HandleInputBuffer, &S, NULL, NULL, 0, &S.mQueue);
    
    PRINT_R;
    
    UInt32 dataFormatSize = sizeof (S.mDataFormat);
    
    r = AudioQueueGetProperty (
                           S.mQueue,
                           kAudioConverterCurrentInputStreamDescription,
                           &S.mDataFormat,
                           &dataFormatSize
                           );
    
    S.bufferByteSize = 44100*4;
    
    for (int i = 0; i < NUM_BUFFERS; ++i) {           
        r = AudioQueueAllocateBuffer(S.mQueue, S.bufferByteSize, &S.mBuffers[i]);
        PRINT_R;
        
        r = AudioQueueEnqueueBuffer(S.mQueue, S.mBuffers[i], 0, NULL);
        PRINT_R;
    }
    
    S.mCurrentPacket = 0;           
    S.mIsRunning = true;           
    
    r = AudioQueueStart(S.mQueue, NULL);
    PRINT_R;
    
    // Wait, on user interface thread, until user stops the recording
    r = AudioQueueStop(S.mQueue, true);
    S.mIsRunning = false;
    
    PRINT_R;
    
    r = AudioQueueDispose(S.mQueue, true);

}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
