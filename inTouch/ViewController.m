//
//  ViewController.m
//  inTouch
//
//  Created by Naicheng Wangyu on 03/01/14.
//  Copyright (c) 2014 Naicheng Wangyu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

// Display the name of the current contact
@property (weak, nonatomic) IBOutlet UILabel *displayName;
// Display the frequency as user uses the slider
@property (weak, nonatomic) IBOutlet UILabel *viewFrequency;
// Display the contact picture
@property (weak, nonatomic) IBOutlet UIImageView *contactPicture;

@end

@implementation ViewController

// Button for "manually contacted" someone, that's not a swipe action.
- (IBAction)manuallyContacted:(id)sender {
}

// Slider to adjust the frequency of desired contact
- (IBAction)changeFrequency:(id)sender {
    UISlider *freqSlider = (UISlider *)sender;
    
    // Default value or a pre-existing value needs to be determined

    freqSlider.continuous = YES;
    
    // Select the value of the slider
    int SliderValue;
    
    // Max option is just to set as 365 days, or annually
    if (freqSlider.value > 359){
        SliderValue = (int)365;
    }
    // If frequency is greater than quarterly
    if (freqSlider.value > 120) {
        SliderValue = 30.0 * floor(((int)roundf(freqSlider.value)/30.0)+0.5);
    // If greater than monthly
    }else if (freqSlider.value > 30){
        SliderValue = 10.0 * floor(((int)roundf(freqSlider.value)/10.0)+0.5);
    // If less often than monthly
    }else{
        SliderValue= (int)roundf(freqSlider.value);
    }

    
    // Base case of days selected is 1
    if(SliderValue == 1){
        NSString *message = [NSString stringWithFormat:@"Remind me every day"];
        [self.viewFrequency setText:message];
    } else{
    NSString *message = [NSString stringWithFormat:@"Remind every %d days", SliderValue];
    [self.viewFrequency setText:message];
    }
}
    
- (void)viewDidLoad {
    [super viewDidLoad];
	// After loading the view, have an alert that tells the user what he/she needs to do to use the app. For now, just dialogue box.
    
    UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:@"Quick How-to Guide" message:@"Swipe up to email \n Swipe left to text message \n Swipe right to postpone \n Swipe down to remove from future reminders\n" delegate:nil cancelButtonTitle:@"Got it" otherButtonTitles:nil, nil];
    [myAlert show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
