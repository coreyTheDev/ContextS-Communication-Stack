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
    NSMutableData *incomingDataBuffer;
    int totalBytesRead;
    
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
-(void)closeStream
{
    [inputStream setDelegate:nil];
    [inputStream close];
    [inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
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
    inputStream = stream;
    [inputStream open];
    [inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [inputStream setDelegate:self];
    incomingDataBuffer = [[NSMutableData alloc]init];
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
            
            len = [inputStream read:buffer maxLength:sizeof(buffer)];
            if (len > 0)
            {
                [incomingDataBuffer appendBytes:&buffer length:len];
                totalBytesRead += len;
                NSLog(@"Read %d bytes, total read bytes: %d",len, totalBytesRead);
                
                if (contextConnection)
                {
                    NSMutableData *newData = [[NSMutableData alloc]init];
                    [newData appendBytes:buffer length:len];
                    [contextConnection writeData:newData withTimeout:10 tag:1];
                }
            }
        }break;
        case NSStreamEventEndEncountered:
        {
            NSLog(@"End Encountered");
            [self closeStream];
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
