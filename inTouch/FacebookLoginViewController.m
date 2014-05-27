//
//  FacebookLoginViewController.m
//  inTouch
//
//  Created by Michael Wu on 5/27/14.
//  Copyright (c) 2014 inTouch. All rights reserved.
//

#import "FacebookLoginViewController.h"

@interface FacebookLoginViewController ()
@end

@implementation FacebookLoginViewController

@synthesize fbLoginView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set default Facebook login behavior
    [fbLoginView setLoginBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent];
    
    // Load in background image
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// Pop to parent view controller
- (IBAction)dismiss:(id)sender {
    [[self navigationController] popViewControllerAnimated:YES];
}

@end
