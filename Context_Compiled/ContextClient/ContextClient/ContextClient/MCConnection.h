//
//  Connection.h
//  ContextClient
//
//  Created by zanotti on 10/16/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MCBrowserViewController.h>
#import <MultipeerConnectivity/MCNearbyServiceAdvertiser.h>
#import <MultipeerConnectivity/MCPeerID.h>
#import <MultipeerConnectivity/MCSession.h>

@interface MCConnection : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, NSStreamDelegate>

@property (strong, nonatomic) MCPeerID *peerID;
@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;

-(id)init;
-(void)connect;
-(void)disconnect;
-(BOOL)sendImage:(UIImage *)image;
-(BOOL)sendImages:(NSArray *)images;
-(BOOL)isConnected;
-(float)getProgress;
@end
