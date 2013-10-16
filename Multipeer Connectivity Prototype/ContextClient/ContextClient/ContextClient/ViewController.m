//
//  ViewController.m
//  ContextClient
//
//  Created by zanotti on 10/1/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import "ViewController.h"

static NSString *const terminatorString = @"end";

@implementation ViewController
{
    UIImagePickerController *imagePicker;
    UIPopoverController *imagePopoverController;
    
    UIImage *selectedImage;
    
    Connection *connection;
}
@synthesize imageSelectButton = _imageSelectButton, imageView = _imageView, reconnectButton = _reconnectButton, streamSwitch = _streamSwitch;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_reconnectButton addTarget:self action:@selector(requestInfo:) forControlEvents:UIControlEventTouchUpInside];
    
    [_imageSelectButton addTarget:self action:@selector(showCameraPopup:) forControlEvents:UIControlEventTouchUpInside];
    
    [_streamSwitch addTarget:self action:@selector(changeConnection:) forControlEvents:UIControlEventValueChanged];
    
    connection = [[Connection alloc]init];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateProgress:) name:@"PROGRESS" object:nil];
}
-(void)viewWillAppear:(BOOL)animated
{
    
}

-(void)viewDidAppear:(BOOL)animated
{
    //[self presentViewController:_browserVC animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

#pragma mark - Utility/Interface Methods
-(IBAction)requestInfo:(id)sender
{
    NSLog(@"Connection Status: %d",[connection isConnected]);
}

-(IBAction)changeConnection:(id)sender
{
    if ([_streamSwitch isOn])
    {
        [connection connect];
    } else
    {
        [connection disconnect];
    }
}
-(void)updateProgress:(NSNotification *)note
{
    [_progressBar setProgress:[connection getProgress]];
}


#pragma mark - Source Methods
-(IBAction)showCameraPopup:(id)sender{
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        [imagePicker setDelegate:self];
        
        // Displays saved pictures and movies, if both are available, from the
        // Camera Roll album.
        imagePicker.mediaTypes =
        [UIImagePickerController availableMediaTypesForSourceType:
         UIImagePickerControllerSourceTypeSavedPhotosAlbum];
        
        // Hides the controls for moving & scaling pictures, or for
        // trimming movies. To instead show the controls, use YES.
        imagePicker.allowsEditing = NO;
        
        imagePicker.delegate = self;
        
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        imagePicker = [[UIImagePickerController alloc]init];
        [imagePicker setDelegate:self];
        imagePopoverController = [[UIPopoverController alloc]initWithContentViewController:imagePicker];
        [imagePopoverController presentPopoverFromRect:[_imageSelectButton frame] inView:[self view]  permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //Setup Image
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [self dismissViewControllerAnimated:YES completion:^{
            selectedImage = [info valueForKey:UIImagePickerControllerOriginalImage];
            [_imageView setImage:selectedImage];
        }];

    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [imagePopoverController dismissPopoverAnimated:YES];
        selectedImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    }
    
    [connection sendImage:selectedImage];
}

@end
