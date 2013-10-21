//
//  MCTether.m
//  ContextClient
//
//  Created by zanotti on 10/17/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import "MCTether.h"

@implementation MCTether
{
    NSInputStream *inputStream;
    NSInputStream *messageStream;
    NSMutableData *incomingDataBuffer;
    NSMutableData *messageBuffer;
    int totalBytesRead;
    int totalMessageBytesRead;
    GCDAsyncSocket *contextConnection;
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

-(void)createTetherWithSocket:(GCDAsyncSocket *)socket
{
    assert([socket connectedHost]);
    contextConnection = socket;
    
    _session = [[MCSession alloc]initWithPeer:_peerID];
    [_session setDelegate:self];
    
    _browser = [[MCNearbyServiceBrowser alloc]initWithPeer:_peerID serviceType:@"Context-s"];
    [_browser setDelegate:self];
    [_browser startBrowsingForPeers];
}
-(void)disconnect
{
    [_browser stopBrowsingForPeers];
    [_session disconnect];
    _browser = nil;
    _session = nil;
}



#pragma mark - Internal Methods
-(void)closeStream:(NSStream *)stream
{
    [stream setDelegate:nil];
    [stream close];
    [stream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    if (stream == messageStream)
    {
        messageStream = nil;
        totalMessageBytesRead = 0;
        messageBuffer = nil;
        return;
    }
    inputStream = nil;
    totalBytesRead = 0;
    incomingDataBuffer = nil;
}


#pragma mark - Browser delegate methods
-(void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"Found Peer with ID:%@",[peerID displayName]);
    [_browser invitePeer:peerID toSession:_session withContext:Nil timeout:30];
}
-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Lost Peer with ID:%@",[peerID displayName]);
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
    /*
     If the user has a stream and gets this request what do we do?
     
     ***Wait message back to user
     ***Begin message back to user
     ***re-receive stream
     */
    if ([streamName isEqualToString: @"messageStream"]){
        messageStream = stream;
        messageBuffer = [[NSMutableData alloc]init];
    } else if ([streamName isEqualToString:@"imageStream"])
    {
        inputStream = stream;
        incomingDataBuffer = [[NSMutableData alloc]init];
    }
    [stream open];
    [stream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [stream setDelegate:self];
    NSLog(@"Got stream:%@ from:%@", streamName,[peerID displayName]);
    
    /*
    if (macConnection)
    {
        NSString *pingString = [[NSString alloc]initWithFormat:@"Image from %@", [peerID displayName]];
        NSMutableData *pingMessage = [[NSMutableData alloc]initWithData:[pingString dataUsingEncoding:NSUTF8StringEncoding]];
        [pingMessage appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
        [[macConnection socket] writeData:pingMessage withTimeout:2 tag:0];
    }
     */
}




#pragma mark - Stream Delegate
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    
    switch(eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            NSLog(@"Bytes Available");
            uint8_t buffer[1024];
            int len;
            
            len = [(NSInputStream *)stream read:buffer maxLength:sizeof(buffer)];
            if (len > 0)
            {
                if (stream == messageStream)
                {
                    [messageBuffer appendBytes:&buffer length:len];
                    totalMessageBytesRead += len;
                    NSLog(@"Read message %d bytes, total read bytes: %d",len, totalBytesRead);
                    if (_messageSocket)
                    {
                        NSMutableData *newData = [[NSMutableData alloc]init];
                        [newData appendBytes:buffer length:len];
                        [_messageSocket writeData:newData withTimeout:10 tag:1];
                    }
                }
                else
                {
                    [incomingDataBuffer appendBytes:&buffer length:len];
                    totalBytesRead += len;
                    NSLog(@"Read image %d bytes, total read bytes: %d",len, totalBytesRead);
                    if (contextConnection)
                    {
                        NSMutableData *newData = [[NSMutableData alloc]init];
                        [newData appendBytes:buffer length:len];
                        [contextConnection writeData:newData withTimeout:10 tag:1];
                    }
                }
            }
        }break;
        case NSStreamEventEndEncountered:
        {
            NSLog(@"End Encountered");
            [self closeStream:stream];
        }break;
        case NSStreamEventNone:
            break;
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"Stream Error occured");
        } break;
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"Stream opend successfully");
        }break;
        default:
            break;
    }
}



@end
