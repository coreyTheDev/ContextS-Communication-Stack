//
//  AsyncConnection.h
//  ContextXL
//
//  Created by zanotti on 10/11/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface AsyncConnection : NSObject <GCDAsyncSocketDelegate>
@property (nonatomic, retain) GCDAsyncSocket *listeningSocket;
@property (nonatomic, retain) GCDAsyncSocket *connectionSocket;
@property (nonatomic, retain) GCDAsyncSocket *ipadSocket;//connected socket
-(BOOL)connect;
-(void)disconnect;
-(NSData *)getImageData;
-(NSString *)getMessage;
@end