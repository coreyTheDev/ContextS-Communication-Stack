//
//  ViewController.h
//  ContextClient
//
//  Created by zanotti on 10/1/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCConnection.h"
#import "BonjourConnection.h"
#import "MCTether.h"
#import "CustomAlertViewViewController.h"
#import "ELCImagePickerController.h"
#import "ELCAlbumPickerController.h"

#define NOTIFICATION_IMAGE_SELECTED @"image_selected"
#define NOTIFICATION_DONE_EDITING @"text_return"
#define NOTIFICATION_TEXT_RECEIVED @"text_received"

@interface ViewController : UIViewController <ELCImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;
@property (weak, nonatomic) IBOutlet UIButton *imageSelectButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *reconnectButton;
@property (weak, nonatomic) IBOutlet UISwitch *streamSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *tetherSwitch;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel *tetherLabel;


@end
