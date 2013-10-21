//
//  BonjourServer.m
//  ContextXL
//
//  Created by zanotti on 10/17/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import "BonjourServer.h"
//needs to broadcast its name over wifi network
//needs to setup async connection for each connected device

static NSString *const terminatorString = @"thisistheendofthemessage";

@implementation BonjourServer

-(id)init
{
    self = [super init];
    if (self)
    {
        connectedSockets = [[NSMutableArray alloc]init];
        asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

-(void)publish
{
    NSError *err = nil;
    if ([asyncSocket acceptOnPort:0 error:&err])
    {
        // So what port did the OS give us?
        
        UInt16 port = [asyncSocket localPort];
        
        // Create and publish the bonjour service.
        // Obviously you will be using your own custom service type.
        
        netService = [[NSNetService alloc] initWithDomain:@""
                                                     type:@"_context._tcp."
                                                     name:@""
                                                     port:port];
        
        [netService setDelegate:self];
        [netService publish];
        
        NSLog(@"Service published");
    } else
    {
        NSLog(@"Service not published");
    }
}
-(NSString *)getMessage{
    return pingMessage;
}
-(NSData *)getImageData
{
    return inputBuffer;
}


#pragma mark - Internal Methods
-(NSMutableData *)removeDelimittersFromData:(NSMutableData *)data
{
    NSUInteger termLen = [terminatorString dataUsingEncoding:NSUTF8StringEncoding].length;
    [data replaceBytesInRange:NSMakeRange(data.length - termLen, termLen) withBytes:NULL length:0];
    return data;
}
-(IBAction)connectionTimeout:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BONJOUR_TIMEOUT" object:nil];
}



#pragma mark - NSNetService delegate methods

- (void)netServiceDidPublish:(NSNetService *)ns
{
	NSLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)",
			  [ns domain], [ns type], [ns name], (int)[ns port]);
}

- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict
{
	// Override me to do something here...
	//
	// Note: This method in invoked on our bonjour thread.
	
	NSLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@",
               [ns domain], [ns type], [ns name], errorDict);
}
-(void)netServiceWillResolve:(NSNetService *)sender
{
    NSLog(@"Resolving Bonjour connection");
}
-(void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog(@"Bonjour connection resolved");
}


#pragma mark - GCDAsyncSocket delegate methods
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	NSLog(@"Accepted new socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
	
	// The newSocket automatically inherits its delegate & delegateQueue from its parent.
	
	[connectedSockets addObject:newSocket];
    [newSocket readDataToData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	[connectedSockets removeObject:sock];
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
    
    [sock readDataToData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
}

//Utility Methods

@end
