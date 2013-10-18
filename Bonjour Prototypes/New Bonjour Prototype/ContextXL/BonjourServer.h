//
//  BonjourServer.h
//  ContextXL
//
//  Created by zanotti on 10/17/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface BonjourServer : NSObject <NSNetServiceDelegate, GCDAsyncSocketDelegate>
{
	NSNetService *netService;
	GCDAsyncSocket *asyncSocket;
	NSMutableArray *connectedSockets;
    
    NSMutableData *inputBuffer;
    NSString *pingMessage;
    
    NSTimer *connectionTimeout;
}

-(void)publish;
-(NSString *)getMessage;
-(NSData *)getImageData;
@end
