//
//  POVViewController.m
//  POV
//
//  Created by Daniel Moreh on 12/30/13.
//  Copyright (c) 2013 Daniel Moreh. All rights reserved.
//

#import "POVViewController.h"
#import <AFNetworking/AFNetworking.h>

@interface POVViewController ()

@end

@implementation POVViewController

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // Send the video to the server
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"lat": @123.123,
                                 @"long": @456.456,
                                 @"timestamp": @([[NSDate date] timeIntervalSince1970])};
    NSURL *filePath = [info objectForKey:UIImagePickerControllerMediaURL];
    [manager POST:@"http://192.168.112.148:3000/upload" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:filePath name:@"video" error:nil];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success: %@", responseObject);
        [picker dismissViewControllerAnimated:YES completion:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
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
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.mediaTypes = @[(NSString *)kUTTypeMovie];
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        picker.allowsEditing = NO;
        picker.videoQuality = UIImagePickerControllerQualityTypeLow;

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

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    UIButton *syncButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    [syncButton setCenter:CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMidY(self.view.frame))];
    [syncButton setTitle:@"Go" forState:UIControlStateNormal];
    [syncButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [syncButton addTarget:self action:@selector(presentCameraView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:syncButton];
    
    NSLog(@"name: %@", [[UIDevice currentDevice] name]);
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
