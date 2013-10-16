//
//  ViewController.h
//  ContextClient
//
//  Created by zanotti on 10/1/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Connection.h"

#define NOTIFICATION_IMAGE_SELECTED @"image_selected"
#define NOTIFICATION_DONE_EDITING @"text_return"
#define NOTIFICATION_TEXT_RECEIVED @"text_received"

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;
@property (weak, nonatomic) IBOutlet UIButton *imageSelectButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *reconnectButton;
@property (weak, nonatomic) IBOutlet UISwitch *streamSwitch;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;

@end
