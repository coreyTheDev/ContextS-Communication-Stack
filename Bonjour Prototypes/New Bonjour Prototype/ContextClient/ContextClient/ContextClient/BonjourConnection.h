//
//  BonjourConnection.h
//  ContextClient
//
//  Created by zanotti on 10/17/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface BonjourConnection : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate, NSStreamDelegate>
{
	NSNetServiceBrowser *netServiceBrowser;
	NSNetService *serverService;
	NSMutableArray *serverAddresses;
    
    NSMutableData *outgoingDataBuffer;
    
	BOOL connected;
    NSTimer *connectionTimeout;
}
@property (nonatomic, retain) GCDAsyncSocket *asyncSocket;

-(void)connect;
-(void)disconnect;
-(BOOL)sendImage:(UIImage *)image;
-(BOOL)isConnected;
@end
