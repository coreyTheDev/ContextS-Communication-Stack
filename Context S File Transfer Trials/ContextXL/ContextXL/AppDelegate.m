//
//  AppDelegate.m
//  ContextXL
//
//  Created by zanotti on 9/30/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import "AppDelegate.h"
#import "GCDAsyncSocket.h"


@implementation AppDelegate
{
    Server *server;
    Connection *contextConnection;
    AsyncConnection *asyncConnection;
    BOOL thumbnail;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    NSAttributedString *newString = [[NSAttributedString alloc]initWithString:@"App Initiated"];
    [[_textView textStorage] appendAttributedString:newString];
    
    //resize window
    [[self window] setFrame:NSRectFromCGRect(CGRectMake(0, 0, 1024, 768)) display:YES];
    [_textView setFrame:NSRectFromCGRect(CGRectMake(0, 0, 900, 500))];
    
    //add listeners for server events
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showImage:) name:@"Image finished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMessage:) name:@"Ping received" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showConnection:) name:@"new connection" object:nil];

    asyncConnection = [[AsyncConnection alloc]init];
    thumbnail = true;
}
-(IBAction)beginBroadcasting:(id)sender
{
    [asyncConnection connect];
    [[_textView textStorage ]appendAttributedString:[[NSAttributedString alloc]initWithString:@"\nSocket Connection Open\n"]];
}

-(void)showConnection:(NSNotification *)note
{
    [[_textView textStorage ]appendAttributedString:[[NSAttributedString alloc]initWithString:[NSString stringWithFormat:@"New Connection at : %@", [note object]]]];
    [[_textView textStorage]appendAttributedString:[[NSAttributedString alloc]initWithString:@"\n"]];
}
-(IBAction)showMessage:(id)sender
{
    [[_textView textStorage ]appendAttributedString:[[NSAttributedString alloc]initWithString:[asyncConnection getMessage]]];
    [[_textView textStorage]appendAttributedString:[[NSAttributedString alloc]initWithString:@"\n"]];
}
-(IBAction)showImage:(id)sender
{
    [[_textView textStorage ]appendAttributedString:[[NSAttributedString alloc]initWithString:@"Receiving Image\n"]];
    //resize image?
    //send smaller image?
    NSImage *pic = [[NSImage alloc] initWithData:[asyncConnection getImageData]];
    if (thumbnail)
        [_imageView setImage:pic];
    else
        [_largeImageView setImage:pic];
    
    thumbnail = !thumbnail;
}

@end
