//
//  SettingsViewController.m
//  inTouch
//
//  Created by Michael Wu on 4/25/14.
//  Copyright (c) 2014 inTouch Team. All rights reserved.
//

#import "ContactManager.h"
#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dismissCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NO];
}

- (void)dismissSave:(id)sender {
    // save the settings
    [self dismissViewControllerAnimated:YES completion:NO];
}

// Display the "syncing contacts" message and sync contacts
- (IBAction)syncContacts:(id)sender {
    // Show the busy view
//    [self disableInteraction];
//    [DebugLogger log:@"Showing busy view" withPriority:2];
//    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
//        [busyView setAlpha:1];
//        [activityIndicator startAnimating];
//    } completion:^(BOOL finished) {
//        [ContactManager updateInformation];
//        [ContactManager updateUrgency];
//        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//            [busyView setAlpha:0];
//        } completion:^(BOOL finished){
//            [activityIndicator stopAnimating];
//            [self getNextContact];
//        }];
//    }];
}

@end
