//
//  Connection.m
//  ContextClient
//
//  Created by zanotti on 10/16/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import "MCConnection.h"

static NSString *const terminatorString = @"thisistheendofthemessage";
static NSInteger const packetSize = 1024;

@implementation MCConnection
{
    NSOutputStream *messageOutputStream;
    NSOutputStream *pictureOutputStream;
    int totalMessageBytesWritten;
    int totalPictureBytesWritten;
    NSMutableData *pictureBuffer;
    NSMutableData *messageBuffer;
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
    
    if ([_session connectedPeers].count == 0)
    {
        NSLog(@"No connection to Bonjour Service: File send failed");
        return NO;
    }
    //create a data buffer
    //place the data
    //try to write
    pictureBuffer = [[NSMutableData alloc]init];
    messageBuffer = [[NSMutableData alloc]init];
    
    //Part 1: Message
    NSLog(@"sending image");
    NSString *pingString = [[NSString alloc]initWithFormat:@"Image from %@", [[UIDevice currentDevice]name]];
    [messageBuffer appendData:[pingString dataUsingEncoding:NSUTF8StringEncoding]];
    [messageBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    if (![self startNotifyStream:middleMan])
    {
        return NO;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        return YES;
    }
    //Part 2: Thumbnail
    [pictureBuffer appendData: UIImageJPEGRepresentation(image, .25)];
    
    [pictureBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    
    //Part 3: Full size Image
    //[pictureBuffer appendData: UIImageJPEGRepresentation(image, 1)];
    
    //[pictureBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [self startMessageStreamWithPeerID:middleMan];
}
-(BOOL)sendImages:(NSArray *)images
{
    
    if ([_session connectedPeers].count == 0)
    {
        NSLog(@"No connection to Bonjour Service: File send failed");
        return NO;
    }
    //create a data buffer
    //place the data
    //try to write
    pictureBuffer = [[NSMutableData alloc]init];
    messageBuffer = [[NSMutableData alloc]init];
    
    //Part 1: Message
    NSLog(@"sending image");
    NSString *pingString = [[NSString alloc]initWithFormat:@"Images from %@", [[UIDevice currentDevice]name]];
    [messageBuffer appendData:[pingString dataUsingEncoding:NSUTF8StringEncoding]];
    [messageBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (![self startNotifyStream:middleMan])
    {
        return NO;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        return YES;
    }
    
    //Part 2: Thumbnail
    
    for (UIImage *image in images)
    {
        [pictureBuffer appendData: UIImageJPEGRepresentation(image, .25)];
    
        [pictureBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    //Part 3: Full size Image
    //[pictureBuffer appendData: UIImageJPEGRepresentation(image, 1)];
    
    //[pictureBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [self startMessageStreamWithPeerID:middleMan];

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
-(BOOL)startMessageStreamWithPeerID:(MCPeerID *)peerID
{
    //connection successful, open stream to connection
    NSError *releaseError;
    //grab random name for stream, send stream to middle man
    pictureOutputStream = [_session startStreamWithName:@"imageStream" toPeer:peerID error:&releaseError];
    if (!pictureOutputStream)
    {
        //grab error, determine reasoning behind error
        NSLog(@"Erorr occurred in creating stream");
        return NO;
    }
    NSLog(@"Stream created successfully");
    [pictureOutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [pictureOutputStream setDelegate:self];
    [pictureOutputStream open];
    return YES;
}

-(BOOL)startNotifyStream:(MCPeerID *)peerID
{
    //connection successful, open stream to connection
    NSError *releaseError;
    messageOutputStream = [_session startStreamWithName:@"messageStream" toPeer:peerID error:&releaseError];
    if (!messageOutputStream)
    {
        NSLog(@"Erorr occurred in creating stream");
        return NO;
    }
    NSLog(@"Stream created successfully");
    [messageOutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [messageOutputStream setDelegate:self];
    [messageOutputStream open];
    return YES;
}
-(void)endStream:(NSOutputStream *)streamToEnd
{
    if (streamToEnd == messageOutputStream)
        totalMessageBytesWritten = 0;
    else
        totalPictureBytesWritten = 0;
    [streamToEnd setDelegate:nil];
    [streamToEnd removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [streamToEnd close];
    streamToEnd = nil;
    //totalBytesWritten = 0;
    //outgoingDataBuffer = nil;
}
-(int)sendBytesinBuffer:(NSMutableData *)buffer ToStream:(NSOutputStream *)outputStream
{
    int totalBytesWritten = ((buffer == messageBuffer)? totalMessageBytesWritten : totalPictureBytesWritten);
    
    uint8_t *readBytes = (uint8_t *)[buffer mutableBytes];
    readBytes += totalBytesWritten; // instance variable to move pointer
    int data_len = [buffer length];
    unsigned int len = ((data_len - totalBytesWritten >= 1024) ?
                        1024 : (data_len-totalBytesWritten));
    uint8_t buf[len];
    (void)memcpy(buf, readBytes, len);
    len = [outputStream write:(const uint8_t *)buf maxLength:len];
    NSLog(@"Written %d out of %d bytes",totalBytesWritten, buffer.length);
    
    if (buffer == messageBuffer)
        totalMessageBytesWritten += len;
    else
        totalPictureBytesWritten += len;
    
    return len;
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
    //When we receive data: should only occur when a resume sending message is sent
    
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
            
            unsigned int len;
            
            if(aStream == messageOutputStream)
            {
                len = [self sendBytesinBuffer:messageBuffer ToStream:messageOutputStream];
                
            } else {
                len = [self sendBytesinBuffer:pictureBuffer ToStream:pictureOutputStream];
                float progress = (float)totalPictureBytesWritten/(float)pictureBuffer.length;
                currentProgress = [NSNumber numberWithFloat:progress];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PROGRESS" object:currentProgress];
            }
            if (len == 0)
                [self endStream:(NSOutputStream *)aStream];
            
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
