//
//  AppDelegate.m
//  ContextXL
//
//  Created by zanotti on 9/30/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate
{
    Server *server;
    Connection *contextConnection;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    NSAttributedString *newString = [[NSAttributedString alloc]initWithString:@"Bonjour App Initiated"];
    [[_textView textStorage] appendAttributedString:newString];
    //resize window
    [[self window] setFrame:NSRectFromCGRect(CGRectMake(0, 0, 1024, 768)) display:YES];
    [_textView setFrame:NSRectFromCGRect(CGRectMake(0, 0, 900, 500))];
}
-(IBAction)beginBroadcasting:(id)sender
{
    //whats the time?
    //its time to get ill
    server = [[Server alloc]init];
    [server setDelegate:self];
    BOOL result = [server start];
    if (result)
    {
        [[_textView textStorage ]appendAttributedString:[[NSAttributedString alloc]initWithString:@"\nBroadcasting Bonjour Service"]];
        NSLog(@"broadcasting service");
    } else {
        [[_textView textStorage ]appendAttributedString:[[NSAttributedString alloc]initWithString:@"\nFailed to Broadcast Service"]];
        NSLog(@"not broadcasting right now");
    }
    
}

#pragma server delegate
-(void)serverFailed:(Server *)server reason:(NSString *)reason
{
    
}
-(void)handleNewConnection:(Connection *)connection
{
    contextConnection = connection;
    [contextConnection setDelegate:self];
    [[_textView textStorage ]appendAttributedString:[[NSAttributedString alloc]initWithString:@"\nConnected to user:"]];
    [[_textView textStorage ]appendAttributedString:[[NSAttributedString alloc]initWithString:[connection getHostName]]];
    
}

#pragma Connection Delegate
-(void)connectionAttemptFailed:(Connection *)connection
{
    
}
-(void)connectionAttemptSucceeded
{
    
}
-(void)connectionTerminated:(Connection *)connection
{
    
}
-(void)receivedNetworkPacket:(NSDictionary *)message viaConnection:(Connection *)connection
{
    //code to handle socket transfer
    if ([message objectForKey:@"message"])
    {
        [[_textView textStorage ]appendAttributedString:[[NSAttributedString alloc]initWithString:[message valueForKey:@"message"]]];
    }
    else if ([message objectForKey:@"image"])
    {
        [[_textView textStorage ]appendAttributedString:[[NSAttributedString alloc]initWithString:@"\nReceiving Image from "]];
        [[_textView textStorage ]appendAttributedString:[[NSAttributedString alloc]initWithString:[message valueForKey:@"user"]]];
        //resize image?
        //send smaller image?
        NSImage * pic = [[NSImage alloc] initWithData:[message valueForKey:@"image"]];
        //float imageScale = pic.size.height / pic.size.width;
        //NSImage *newImage = [self imageResize:pic newSize:NSSizeFromCGSize(CGSizeMake(300, 300 * imageScale))];
        NSTextAttachmentCell *attachmentCell = [[NSTextAttachmentCell alloc] initImageCell:pic];
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        [attachment setAttachmentCell: attachmentCell ];
        NSAttributedString *attributedString = [NSAttributedString  attributedStringWithAttachment: attachment];
        [[_textView textStorage] appendAttributedString:attributedString];
        [_textView scrollRangeToVisible:NSMakeRange([[_textView string]length], 0)];
    }
}

#pragma - Image Resizing Methods
- (NSImage *)imageResize:(NSImage*)anImage
                 newSize:(NSSize)newSize
{
    NSImage *sourceImage = anImage;
    [sourceImage setScalesWhenResized:YES];
    
    // Report an error if the source isn't a valid image
    if (![sourceImage isValid])
    {
        NSLog(@"Invalid Image");
    } else
    {
        NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
        [smallImage lockFocus];
        [sourceImage setSize: newSize];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;
}
@end
