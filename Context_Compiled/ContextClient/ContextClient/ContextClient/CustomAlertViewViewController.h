//
//  CustomAlertViewViewController.h
//  ContextClient
//
//  Created by zanotti on 10/18/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomAlertViewViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *viewBG;
@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UITextView *statusField;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;


-(void)updateMessageWithString:(NSString *)newMessage;
- (IBAction)dismissModalView:(id)sender;

@end
