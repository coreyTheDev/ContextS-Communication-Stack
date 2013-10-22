//
//  CustomAlertViewViewController.m
//  ContextClient
//
//  Created by zanotti on 10/18/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import "CustomAlertViewViewController.h"

@interface CustomAlertViewViewController ()

@end

#define DISMISS_TAG     888
#define ANIMATION_DURATION   .25
@implementation CustomAlertViewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(id)init{
    self = [super init];
    if (self)
    {
        [self.view setBackgroundColor:[UIColor colorWithRed:.33 green:.33 blue:.33 alpha:.75]];
        [self.view setFrame:[[UIScreen mainScreen]bounds]];
        [_activityView startAnimating];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)dismissModalView:(id)sender
{
    [[self view]removeFromSuperview];
}
-(void)updateMessageWithString:(NSString *)newMessage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_statusField setText:newMessage];
    });
}
@end
