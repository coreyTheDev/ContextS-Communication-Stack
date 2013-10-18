//
//  Connection.m
//  ContextClient
//
//  Created by zanotti on 10/16/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import "MCConnection.h"

static NSString *const terminatorString = @"end";
static NSInteger const packetSize = 1024;

@implementation MCConnection
{
    NSOutputStream *outputStream;
    int totalBytesWritten;
    NSMutableData* outgoingDataBuffer;
    MCPeerID *middleMan;
    
    NSNumber *currentProgress;
}

-(id)init
{
    self = [super init];
    if (self)
    {
        _peerID = [[MCPeerID alloc]initWithDisplayName:[NSString stringWithFormat:[[UIDevice currentDevice]name], [NSDate date]]];
    }
    return self;
}

-(void)connect
{
    _session = [[MCSession alloc]initWithPeer:_peerID];
    [_session setDelegate:self];
    
    _advertiser = [[MCNearbyServiceAdvertiser alloc]initWithPeer:_peerID discoveryInfo:nil serviceType:@"Context-s"];
    [_advertiser setDelegate:self];
    [_advertiser startAdvertisingPeer];
}

-(void)disconnect
{
    [_advertiser stopAdvertisingPeer];
    [_session disconnect];
    _advertiser = nil;
    _session = nil;
}

-(BOOL)sendImage:(UIImage *)image
{
    outgoingDataBuffer = [[NSMutableData alloc]init];
    
    //Part 2: Thumbnail
    [outgoingDataBuffer appendData: UIImageJPEGRepresentation(image, .25)];
    
    [outgoingDataBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    
    //Part 3: Full size Image
    [outgoingDataBuffer appendData: UIImageJPEGRepresentation(image, 1)];
    
    
    //[outgoingDataBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    
    //Part 4: Disposable buffer bytes at the end (these get lost)
    //NSData *terminalData = [[NSData alloc]initWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"terminalImage" ofType:@"png"]];
    //[outgoingDataBuffer appendData:terminalData];
    
    //Part 5: Send Image
    return [self startStreamWithPeerID:middleMan];
}

-(BOOL)isConnected
{
    return ([_session connectedPeers].count > 0);
}
-(float)getProgress
{
    return [currentProgress floatValue];
}


#pragma mark - Additional Classes
-(BOOL)startStreamWithPeerID:(MCPeerID *)peerID
{
    //connection successful, open stream to connection
    NSError *releaseError;
    outputStream = [_session startStreamWithName:@"imageStream" toPeer:peerID error:&releaseError];
    if (!outputStream)
    {
        NSLog(@"Erorr occurred in creating stream");
        return NO;
    }
    NSLog(@"Stream created successfully");
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream setDelegate:self];
    [outputStream open];
    return YES;
}
-(void)endStream
{
    [outputStream setDelegate:nil];
    [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream close];
    outputStream = nil;
    totalBytesWritten = 0;
    outgoingDataBuffer = nil;
}


//DELEGATE METHODS


#pragma mark - Advertisement methods
-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    NSLog(@"Received invitation from: %@", [peerID displayName]);
    invitationHandler(YES,_session);//auto join session
    middleMan = peerID;
}
-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"Error in advertising: %@", [error localizedDescription]);
}



#pragma Session Delegate Methods
-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnected)
    {
        NSLog(@"Connected User: %@ with total users now at: %d", peerID, [[_session connectedPeers] count]);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MULTIPEER_CONNECT" object:nil];
    }
    else if (state == MCSessionStateNotConnected)
    {
        NSLog(@"User: %@ disconnected with total users now at: %d", peerID, [[_session connectedPeers] count]);
    }
}
-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
}
-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
}
-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}
-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
}




#pragma mark - Stream Delegate
-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            //[self updateStatus:@"Opened connection"];
            NSLog(@"Stream opened");
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"Stream has space available");
            
            uint8_t *readBytes = (uint8_t *)[outgoingDataBuffer mutableBytes];
            readBytes += totalBytesWritten; // instance variable to move pointer
            int data_len = [outgoingDataBuffer length];
            unsigned int len = ((data_len - totalBytesWritten >= 1024) ?
                                1024 : (data_len-totalBytesWritten));
            uint8_t buf[len];
            (void)memcpy(buf, readBytes, len);
            len = [outputStream write:(const uint8_t *)buf maxLength:len];
            totalBytesWritten += len;
            NSLog(@"Written %d out of %d bytes",totalBytesWritten, outgoingDataBuffer.length);
            
            //update progress
            float progress = (float)totalBytesWritten/(float)outgoingDataBuffer.length;
            currentProgress = [NSNumber numberWithFloat:progress];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PROGRESS" object:currentProgress];
            
            if (len == 0)
                [self endStream];
            
        } break;
        case NSStreamEventErrorOccurred: {
            //[self stopSendWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            //assert(NO);
        } break;
    }
}


@end
