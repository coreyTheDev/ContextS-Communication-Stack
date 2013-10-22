//
//  BonjourConnection.m
//  ContextClient
//
//  Created by zanotti on 10/17/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import "BonjourConnection.h"

static NSString *const terminatorString = @"thisistheendofthemessage";

@implementation BonjourConnection

-(id)init
{
    self = [super init];
    if (self)
    {
        netServiceBrowser = [[NSNetServiceBrowser alloc] init];
        
        [netServiceBrowser setDelegate:self];
    }
    return self;
}

-(void)connect
{
    [netServiceBrowser searchForServicesOfType:@"_context._tcp." inDomain:@"local."];
    
    connectionTimeout = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(connectionTimeout:) userInfo:nil repeats:NO];
    NSRunLoop *runner = [NSRunLoop currentRunLoop];
    [runner addTimer:connectionTimeout forMode: NSDefaultRunLoopMode];
}
-(void)disconnect
{
    if (_asyncSocket)
    {
        NSLog(@"Disconnected from Socket connection");
        [_asyncSocket disconnect];
        _asyncSocket = nil;
    }
    [netServiceBrowser stop];
    [connectionTimeout invalidate];
    serverService = nil;
    serverAddresses = nil;
}

-(BOOL)sendImage:(UIImage *)image
{
    if (![_asyncSocket isConnected])
    {
        NSLog(@"No connection to Bonjour Service: File send failed");
        return NO;
    }
    //create a data buffer
    //place the data
    //try to write
    outgoingDataBuffer = [[NSMutableData alloc]init];
    
    //Part 1: Message
    NSLog(@"sending image");
    NSString *pingString = [[NSString alloc]initWithFormat:@"Image from %@", [[UIDevice currentDevice]name]];
    [outgoingDataBuffer appendData:[pingString dataUsingEncoding:NSUTF8StringEncoding]];
    
    [outgoingDataBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    
    //Part 2: Thumbnail
    [outgoingDataBuffer appendData: UIImageJPEGRepresentation(image, .25)];
    
    [outgoingDataBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    
    //Part 3: Full size Image
    //[outgoingDataBuffer appendData: UIImageJPEGRepresentation(image, 1)];
    
    //[outgoingDataBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_asyncSocket writeData:outgoingDataBuffer withTimeout:10.0 tag:0];
    return YES;
}

-(BOOL)sendImages:(NSArray *)images
{
    
    if (![_asyncSocket isConnected])
    {
        NSLog(@"No connection to Bonjour Service: File send failed");
        return NO;
    }
    //create a data buffer
    //place the data
    //try to write
    outgoingDataBuffer = [[NSMutableData alloc]init];
    
    //Part 1: Message
    NSLog(@"sending images");
    NSString *pingString = [[NSString alloc]initWithFormat:@"Images from %@", [[UIDevice currentDevice]name]];
    [outgoingDataBuffer appendData:[pingString dataUsingEncoding:NSUTF8StringEncoding]];
    [outgoingDataBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    
    //Part 2: Thumbnail
    
    for (UIImage *image in images)
    {
        [outgoingDataBuffer appendData: UIImageJPEGRepresentation(image, .25)];
        
        [outgoingDataBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
        
        [outgoingDataBuffer appendData: UIImageJPEGRepresentation(image, 1)];
    
        [outgoingDataBuffer appendData:[terminatorString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    
    //Part 3: Full size Image
    
    
    [_asyncSocket writeData:outgoingDataBuffer withTimeout:(5*images.count) tag:0];
    return YES;
}

-(BOOL)isConnected
{
    if (_asyncSocket)
    {
        return ([_asyncSocket isConnected]);
    }
    else{
        return NO;
    }
}


#pragma mark - Internal Methods

- (void)connectToNextAddress
{
	BOOL done = NO;
	
	while (!done && ([serverAddresses count] > 0))
	{
		NSData *addr;
		
		// Note: The serverAddresses array probably contains both IPv4 and IPv6 addresses.
		//
		// If your server is also using GCDAsyncSocket then you don't have to worry about it,
		// as the socket automatically handles both protocols for you transparently.
		
		if (YES) // Iterate forwards
		{
			addr = [serverAddresses objectAtIndex:0];
			[serverAddresses removeObjectAtIndex:0];
		}
		else // Iterate backwards
		{
			addr = [serverAddresses lastObject];
			[serverAddresses removeLastObject];
		}
		
		NSLog(@"Attempting connection to %@", addr);
		
		NSError *err = nil;
		if ([_asyncSocket connectToAddress:addr error:&err])
		{
			done = YES;
            [_asyncSocket setDelegate:self];
            NSLog(@"Connected to context at %@", [_asyncSocket connectedHost]);
            [netServiceBrowser stop];
            
            //create message socket
            _messageSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
            if ([_messageSocket connectToAddress:addr error:&err])
            {
                NSLog(@"Connected message socket!");
            }
		}
		else
		{
			NSLog(@"Unable to connect: %@", err);
		}
	}
	
	if (!done)
	{
		NSLog(@"Unable to connect to any resolved address");
	}
}
-(IBAction)connectionTimeout:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BONJOUR_TIMEOUT" object:nil];
    NSLog(@"Bonjour Service Timedout");
    [netServiceBrowser stop]; 
}




#pragma mark - NSNetService delegate methods
-(void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    NSLog(@"Searching for Context via Bonjour");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender didNotSearch:(NSDictionary *)errorInfo
{
	NSLog(@"DidNotSearch: %@", errorInfo);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender
           didFindService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
	NSLog(@"DidFindService: %@", [netService name]);
	
	// Connect to the first service we find
	
	if (serverService == nil)
	{
		NSLog(@"Resolving...");
		
		serverService = netService;
		
		[serverService setDelegate:self];
		[serverService resolveWithTimeout:5.0];
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender
         didRemoveService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
	NSLog(@"DidRemoveService: %@", [netService name]);
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)sender
{
	NSLog(@"DidStopSearch");
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	NSLog(@"DidNotResolve");
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	NSLog(@"DidResolve: %@", [sender addresses]);
    
	[connectionTimeout invalidate];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BONJOUR_CONNECTION" object:nil];
    
	if (serverAddresses == nil)
	{
		serverAddresses = [[sender addresses] mutableCopy];
        [netServiceBrowser stop];
        [serverService stop];
	}
	
	if (_asyncSocket == nil)
	{
		_asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
		
		[self connectToNextAddress];
	}
}


#pragma mark - GCDAsyncSocket delegate methods
//Delegate methods
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"Socket did connect to host:%@ on port:%d", host, port);
}
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    //assert (sock == _asyncSocket);
    NSLog(@"Socket wrote data with tag:%ld", tag);
}
-(void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    NSLog(@"Socket wrote %d of %ld", partialLength, tag);
}
-(NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
    NSLog(@"Socket write timed out after %f with %d bytes written", elapsed, length);
    return 0;
}
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"Socket read data");
}


@end
