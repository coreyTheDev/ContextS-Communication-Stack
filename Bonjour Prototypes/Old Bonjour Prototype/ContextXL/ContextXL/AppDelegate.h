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

@interface AppDelegate : NSObject <NSApplicationDelegate, ServerDelegate, ConnectionDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *broadcastButton;
@property (unsafe_unretained) IBOutlet NSTextView *textView;
-(IBAction)beginBroadcasting:(id)sender;


@end
