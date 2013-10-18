//
//  AsyncConnection.m
//  ContextXL
//
//  Created by zanotti on 10/11/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import "AsyncConnection.h"

static NSString *const terminatorString = @"end";
static NSString *const thumbnailTerminator = @"thumbnail";
static NSString *const imageTerminator = @"image";
static NSString *const messageTerminator = @"message";

@implementation AsyncConnection
{
    NSMutableData *inputBuffer;
    NSString *pingMessage;
    dispatch_queue_t listenQueue;
}
@synthesize listeningSocket = _listeningSocket, connectionSocket = _connectionSocket, ipadSocket = _ipadSocket;

-(id)init
{
    self = [super init];
    if (self)
    {
        listenQueue = dispatch_queue_create("listen-queue", NULL);
        _listeningSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:listenQueue];
    }
    return self;
}

-(BOOL)connect
{
    if (!_listeningSocket)
    {
        listenQueue = dispatch_queue_create("listen-queue", NULL);
        _listeningSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:listenQueue];
    }
    NSError *error;
    if (![_listeningSocket acceptOnPort:9000 error:&error])
    {
        NSLog(@"Connection didn't start listening");
        NSLog(@"Connection Error: %@", [error localizedDescription]);
        return false;
    }
    NSLog(@"Accepting on port 9000");
    return true;
}
-(void)disconnect
{
    if (_listeningSocket)
    {
        [_listeningSocket disconnect];
        NSLog(@"Disconnected from Mac");
        return;
    }
}
-(NSData *)getImageData
{
    return inputBuffer;
}
-(NSString *)getMessage
{
    return pingMessage;
}

////Delegate methods
-(dispatch_queue_t)newSocketQueueForConnectionFromAddress:(NSData *)address onSocket:(GCDAsyncSocket *)sock
{
    NSLog(@"New socket queue");
    return (listenQueue);
}
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    //will be called when socket connects
    NSLog(@"Connection Socket connected to ipad at %@",host);
}
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    //called when ipad connects to osx
    assert(sock = _listeningSocket);
    NSLog(@"Connected to Ipad on %@", [newSocket connectedHost]);
    inputBuffer = [[NSMutableData alloc]init];
    _ipadSocket = newSocket;


    [_ipadSocket readDataToData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    //[_ipadSocket readDataToData:[thumbnailTerminator dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:1];
    //[_ipadSocket readDataToData:[imageTerminator dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:2];

    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"new connection" object:[[NSString alloc] initWithString:[newSocket connectedHost]]];
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"Socket %@ did read data with length: %lu", [sock connectedHost], (unsigned long)data.length);
    
    NSMutableData *freshData = [self removeDelimittersFromData:[[NSMutableData alloc]initWithData:data]];
    
    if (freshData.length < 100)
    {
        pingMessage = [[NSString alloc]initWithData:freshData encoding:NSUTF8StringEncoding];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Ping received" object:nil];
    }else{
        inputBuffer = [[NSMutableData alloc]initWithData:freshData];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Image finished" object:nil];
    }
    
    [_ipadSocket readDataToData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"Socket %@ did write data with tag %ld", [sock connectedHost], tag);
}
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"Socket did disconnect");
}
-(NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
    NSLog(@"Socket write will timeout");
    return 0;
}
-(NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Image finished" object:nil];
    NSLog(@"Read timeout after %f with %lu bytes read", elapsed,(unsigned long)length);
    return 0;
}


//Utility Methods
-(NSMutableData *)removeDelimittersFromData:(NSMutableData *)data
{
    NSUInteger termLen = [terminatorString dataUsingEncoding:NSUTF8StringEncoding].length;
    [data replaceBytesInRange:NSMakeRange(data.length - termLen, termLen) withBytes:NULL length:0];
    return data;
}
@end
