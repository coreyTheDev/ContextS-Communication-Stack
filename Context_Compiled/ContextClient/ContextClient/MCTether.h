//
//  MCTether.h
//  ContextClient
//
//  Created by zanotti on 10/17/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MCPeerID.h>
#import <MultipeerConnectivity/MCSession.h>
#import <MultipeerConnectivity/MCNearbyServiceBrowser.h>
#import "GCDAsyncSocket.h"

@interface MCTether : NSObject<MCNearbyServiceBrowserDelegate, MCSessionDelegate, NSStreamDelegate>

@property (strong, nonatomic) MCPeerID *peerID;
@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) GCDAsyncSocket *messageSocket;
-(void)createTetherWithSocket:(GCDAsyncSocket *)socket;
-(void)disconnect;

@end
