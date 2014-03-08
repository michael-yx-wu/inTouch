//
//  ViewController.m
//  inTouch
//
//  Created by Naicheng Wangyu on 03/01/14.
//  Copyright (c) 2014 Naicheng Wangyu. All rights reserved.
//

#import "MainViewController.h"
#import "DebugLogger.h"

@interface MainViewController ()

// Display the name of the current contact
@property (weak, nonatomic) IBOutlet UILabel *displayName;
// Display the frequency as user uses the slider
@property (weak, nonatomic) IBOutlet UILabel *viewFrequency;
// Display the contact picture
@property (weak, nonatomic) IBOutlet UIImageView *contactPicture;

@end

@implementation MainViewController

// Button for "manually contacted" someone, that's not a swipe action.
- (IBAction)manuallyContacted:(id)sender {
    [DebugLogger log:@"Manually contacted current contact" withPriority:1];
    // Update the global count, time, and other values in the core model.
}

// Slider to adjust the frequency of desired contact
- (IBAction)changeFrequency:(id)sender {
    UISlider *freqSlider = (UISlider *)sender;
    
    // Default value or a pre-existing value needs to be determined
    [freqSlider setContinuous:YES];
    [freqSlider setMinimumValue:0];
    [freqSlider setMaximumValue:650];
    
    // Map slider value to remind frequency (in days because of eventual CoreData entry)
    NSInteger frequency;
    NSInteger sliderValue = freqSlider.value;
    if (sliderValue <= 300) {
        frequency = sliderValue/10;
    } else if (sliderValue <= 625) {
        frequency = ((sliderValue-300)/60+1)*30;
    } else {
        frequency = 365;
    }
    
    // Map frequency to user friendly display text
    NSString *message;
    if (frequency == 1) {
        message = @"Remind me every day";
    } else if (frequency <= 30) {
        message = [NSString stringWithFormat:@"Remind me every %ld days", frequency];
    } else if (frequency < 365) {
        NSInteger months = frequency/30;
        message = [NSString stringWithFormat:@"Remind me every %ld months", months];
    } else {
        message = @"Remind me every year";
    }
    
    [self.viewFrequency setText:message];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Alertview with basic instructions.
    UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:@"Quick How-to Guide"
                                                      message:@"Swipe up to email \n Swipe left to text message \n Swipe right to postpone \n Swipe down to remove from future reminders\n"
                                                     delegate:self
                                            cancelButtonTitle:@"Got it"
                                            otherButtonTitles:nil, nil];
    [myAlert show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
