//
//  POVViewController.m
//  POV
//
//  Created by Daniel Moreh on 12/30/13.
//  Copyright (c) 2013 Daniel Moreh. All rights reserved.
//

#import "POVViewController.h"

@interface POVViewController ()

@end

@implementation POVViewController

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)thePicker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // Show uploading HUD.
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:picker.view animated:YES];
    hud.labelText = @"Uploading...";
    
    // Upload the video, then dismiss modal view.
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    CLLocationCoordinate2D coordinate = locationManager.location.coordinate;
    NSDictionary *parameters = @{@"lat": @(coordinate.latitude),
                                 @"long": @(coordinate.longitude),
                                 @"starttime": @(startTime),
                                 @"endtime": @(endTime),
                                 @"duration": @(endTime - startTime),
                                 @"user": [[[UIDevice currentDevice] name] componentsSeparatedByString:@" "][0]};
    NSLog(@"%@", parameters);
    
    NSString *uploadURL = [NSString stringWithFormat:@"%@/upload", IPAddress];
    [manager POST:uploadURL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSURL *filePath = [info objectForKey:UIImagePickerControllerMediaURL];
        [formData appendPartWithFileURL:filePath name:@"video" error:nil];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success: %@", responseObject);
        [picker dismissViewControllerAnimated:YES completion:nil];
        [hud hide:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [picker dismissViewControllerAnimated:YES completion:nil];
        [hud hide:YES];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[NSString stringWithFormat:@"%@", error]
                                                       delegate:self
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
        [alert show];
    }];
}

#pragma mark - Controller
- (void)presentCameraView
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        UIView *overlayView = [[UIView alloc] initWithFrame:self.view.frame];
        UIButton *recordButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        recordButton.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMaxY(self.view.frame) - CGRectGetMidY(recordButton.frame) - 10);
        [recordButton addTarget:self action:@selector(recordButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [overlayView addSubview:recordButton];
        
        picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.mediaTypes = @[(NSString *)kUTTypeMovie];
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        picker.allowsEditing = NO;
        picker.modalPresentationStyle = UIModalPresentationCurrentContext;
        picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        picker.cameraOverlayView = overlayView;
        
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"This device does not have a camera."
                                                       delegate:self
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)toggleIPField
{
    if (IPTextField.hidden) {
        IPTextField.hidden = NO;
    } else {
        IPAddress = IPTextField.text;
        [[NSUserDefaults standardUserDefaults] setValue:IPAddress forKey:@"IP"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [IPTextField resignFirstResponder];
        IPTextField.hidden = YES;
    }
}

- (void)recordButtonPressed
{
    static BOOL isRecording = NO;
    
    BOOL wasRecording = isRecording;
    isRecording = !isRecording;
    
    if (wasRecording) {
        [picker stopVideoCapture];
        [picker.cameraOverlayView setUserInteractionEnabled:NO];
        picker.cameraOverlayView = nil;
    } else {
        [picker startVideoCapture];
    }
    
    Firebase *offsetRef = [[Firebase alloc] initWithUrl:@"https://SampleChat.firebaseIO-demo.com/.info/serverTimeOffset"];
    [offsetRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        float offset = [(NSNumber *)snapshot.value floatValue];
        float serverTimeMs = [[NSDate date] timeIntervalSince1970] * 1000.0 + offset;
        
        if (wasRecording) {
            endTime = serverTimeMs;
        } else {
            startTime = serverTimeMs;
        }
    }];
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    UIButton *syncButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
    [syncButton setCenter:CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMidY(self.view.frame))];
    [syncButton setTitle:@"Go" forState:UIControlStateNormal];
    [syncButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [syncButton addTarget:self action:@selector(presentCameraView) forControlEvents:UIControlEventTouchUpInside];
    [syncButton addTarget:self action:@selector(toggleIPField) forControlEvents:UIControlEventTouchUpOutside];
    [self.view addSubview:syncButton];
    
    // Secret field to input IP Address
    IPAddress = [[NSUserDefaults standardUserDefaults] valueForKey:@"IP"];
    if (!IPAddress) {
        IPAddress = @"http://192.168.112.148:3000";
        [[NSUserDefaults standardUserDefaults] setValue:IPAddress forKey:@"IP"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    IPTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
    IPTextField.text = IPAddress;
    IPTextField.hidden = YES;
    [self.view addSubview:IPTextField];
    
    locationManager = [[CLLocationManager alloc] init];
    [locationManager startUpdatingLocation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
