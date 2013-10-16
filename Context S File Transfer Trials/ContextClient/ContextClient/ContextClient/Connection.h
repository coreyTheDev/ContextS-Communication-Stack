//
//  Connection.h
//  ContextClient
//
//  Created by zanotti on 10/16/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MCPeerID.h>
#import <MultipeerConnectivity/MCSession.h>
#import <MultipeerConnectivity/MCNearbyServiceBrowser.h>
#import <MultipeerConnectivity/MCBrowserViewController.h>
#import <MultipeerConnectivity/MCNearbyServiceAdvertiser.h>


@interface Connection : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, NSStreamDelegate>

@property (strong, nonatomic) MCPeerID *peerID;
@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;

-(id)init;
-(void)connect;
-(void)disconnect;
-(BOOL)sendImage:(UIImage *)image;
-(BOOL)isConnected;
-(float)getProgress;

@end
