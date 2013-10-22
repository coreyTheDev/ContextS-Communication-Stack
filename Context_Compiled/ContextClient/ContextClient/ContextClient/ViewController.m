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
    ELCImagePickerController *imagePicker;
    UIPopoverController *imagePopoverController;
    NSMutableArray *imageArray;
    
    UIImage *selectedImage;
    
    MCConnection *multipeerConnection;
    BonjourConnection *bonjourConnection;
    MCTether *multipeerTether;
    
    CustomAlertViewViewController *connectionView;
}
@synthesize imageSelectButton = _imageSelectButton, imageView = _imageView, reconnectButton = _reconnectButton, streamSwitch = _streamSwitch;



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_reconnectButton addTarget:self action:@selector(requestInfo:) forControlEvents:UIControlEventTouchUpInside];
    
    [_imageSelectButton addTarget:self action:@selector(showCameraPopup:) forControlEvents:UIControlEventTouchUpInside];
    
    [_streamSwitch addTarget:self action:@selector(changeConnection:) forControlEvents:UIControlEventValueChanged];
    
    
    bonjourConnection = [[BonjourConnection alloc]init];
    [bonjourConnection connect];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(establishConnection:) name:@"BONJOUR_CONNECTION" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(bonjourFail:) name:@"BONJOUR_TIMEOUT" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateProgress:) name:@"PROGRESS" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dismissConnectionView:) name:@"DISMISS_CONNECTIONVIEW" object:nil];
    
    connectionView = [[CustomAlertViewViewController alloc]init];
    [[self view] addSubview:[connectionView view]];
    [self presentViewController:connectionView animated:YES completion:nil];
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
        if (!bonjourConnection)
            bonjourConnection = [[BonjourConnection alloc]init];
        
        [bonjourConnection connect];
    } else
    {
        //switch is off, disconnect from everything
        if (bonjourConnection){
            [bonjourConnection disconnect];
            if (multipeerTether)
            {
                [multipeerTether disconnect];
                multipeerTether = nil;
            }
            [_tetherSwitch setEnabled:NO];
            [_tetherLabel setEnabled:NO];
        }
        else if (multipeerConnection)
            [multipeerConnection disconnect];
    }
}
-(IBAction)bonjourFail:(id)sender
{
    [bonjourConnection disconnect];
    bonjourConnection = nil;
    [connectionView updateMessageWithString:@"No Bonjour service found. Connecting through P2P."];
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
        [multipeerTether setMessageSocket:[bonjourConnection messageSocket]];
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
        
        [connectionView updateMessageWithString:@"Connected with Bonjour"];
    } else {
        [connectionView updateMessageWithString:@"Connected through P2P"];
    }
}
-(void)dismissConnectionView:(NSNotification *)note
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Source Methods
-(IBAction)showCameraPopup:(id)sender{
    
    ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] initWithNibName: nil bundle: nil];
	imagePicker = [[ELCImagePickerController alloc] initWithRootViewController:albumController];
    imagePicker.maximumImagesCount = 100;
    [albumController setParent:imagePicker];
	[imagePicker setDelegate:self];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        imagePopoverController = [[UIPopoverController alloc]initWithContentViewController:imagePicker];
        [imagePopoverController presentPopoverFromRect:[_imageSelectButton frame] inView:[self view]  permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
}
-(void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    //Here we have an array of NSDictionary objects
    /*
        Loop through
        Grab each photo
        Downsize to .25 quality
        Add it to secondary array
     */
    imageArray = [[NSMutableArray alloc]init];
    for (NSDictionary *photoInfo in info)
    {
        UIImage *temp = [photoInfo valueForKey:UIImagePickerControllerOriginalImage];
        [imageArray addObject:temp];
        NSLog(@"Number of images = %d", [imageArray count]);
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [imagePopoverController dismissPopoverAnimated:YES];
    }
    
    [self sendImages];
}
-(void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [imagePopoverController dismissPopoverAnimated:YES];
    }

}

-(void)sendImages
{
    /*
       Loop through images array
        send each image through whatever connection is available
     */
    if (bonjourConnection)
        [bonjourConnection sendImages:imageArray];
    else if (multipeerConnection)
        [multipeerConnection sendImages:imageArray];
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
