//
//  ViewController.m
//  ContextClient
//
//  Created by zanotti on 10/1/13.
//  Copyright (c) 2013 zanotti. All rights reserved.
//

#import "ViewController.h"

static NSString *const terminatorString = @"end";


/*
    Process: Try Bonjour connection
    Listen for notifications
    On timeout notification: create MCConnection class
    On connection: show that were connected, allow for user interaction
 */

@implementation ViewController
{
    UIImagePickerController *imagePicker;
    UIPopoverController *imagePopoverController;
    
    UIImage *selectedImage;
    
    MCConnection *multipeerConnection;
    BonjourConnection *bonjourConnection;
    MCTether *multipeerTether;
}
@synthesize imageSelectButton = _imageSelectButton, imageView = _imageView, reconnectButton = _reconnectButton, streamSwitch = _streamSwitch;



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_reconnectButton addTarget:self action:@selector(requestInfo:) forControlEvents:UIControlEventTouchUpInside];
    
    [_imageSelectButton addTarget:self action:@selector(showCameraPopup:) forControlEvents:UIControlEventTouchUpInside];
    
    [_streamSwitch addTarget:self action:@selector(changeConnection:) forControlEvents:UIControlEventValueChanged];
    
    
    bonjourConnection = [[BonjourConnection alloc]init];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(establishConnection:) name:@"BONJOUR_CONNECTION" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(bonjourFail:) name:@"BONJOUR_TIMEOUT" object:nil];
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
    NSLog(@"Connection Status: %d",[multipeerConnection isConnected]);
}

-(IBAction)changeConnection:(id)sender
{
    if ([_streamSwitch isOn])
    {
        [bonjourConnection connect];
    } else
    {
        if (bonjourConnection)
            [bonjourConnection disconnect];
        else if (multipeerConnection)
            [multipeerConnection disconnect];
    }
}
-(IBAction)bonjourFail:(id)sender
{
    [bonjourConnection disconnect];
    bonjourConnection = nil;
    [self multipeerInit];
}
-(IBAction)createTether:(id)sender
{
    if ([_tetherSwitch isOn])
    {
        if (multipeerConnection)
        {
            [multipeerConnection disconnect];
        }
        multipeerTether = [[MCTether alloc]init];
        [multipeerTether createTetherWithSocket:[bonjourConnection asyncSocket]];
    }
    else
    {
        if (multipeerTether)
        {
            [multipeerConnection disconnect];
        }
    }
}
-(void)updateProgress:(NSNotification *)note
{
    [_progressBar setProgress:[multipeerConnection getProgress]];
}

-(void)multipeerInit
{
    NSLog(@"Creating Multipeer connection");
    
    if (!multipeerConnection)
    {
        multipeerConnection = [[MCConnection alloc]init];
        [multipeerConnection connect];
    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(establishConnection:) name:@"MULTIPEER_CONNECT" object:nil];
    }
}
-(IBAction)establishConnection:(id)sender
{
    NSLog(@"CONNECTION");
    if (bonjourConnection)
    {
        [_tetherSwitch setEnabled:YES];
        [_tetherLabel setEnabled:YES];
        
        [_tetherSwitch addTarget:self action:@selector(createTether:) forControlEvents:UIControlEventValueChanged];
    }
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
    if (bonjourConnection)
        [bonjourConnection sendImage:selectedImage];
    else if (multipeerConnection)
        [multipeerConnection sendImage:selectedImage];
}

@end
