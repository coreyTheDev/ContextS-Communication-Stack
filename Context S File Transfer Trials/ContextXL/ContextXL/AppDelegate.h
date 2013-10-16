//
//  AppDelegate.h
//  ContextXL
//
//  Created by zanotti on 9/30/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Server.h"
#import "ConnectionDelegate.h"
#import "Connection.h"
#import "AsyncConnection.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *broadcastButton;
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSImageView *imageView;
@property (weak) IBOutlet NSImageView *largeImageView;
-(IBAction)beginBroadcasting:(id)sender;


@end
