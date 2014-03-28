//
//  ContactViewController.m
//  inTouch
//
//  Created by Michael Wu on 3/24/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

#import "ContactViewController.h"

@interface ContactViewController ()

@end

@implementation ContactViewController

@synthesize nameLabel;
@synthesize photoView;
@synthesize name;
@synthesize photo;
@synthesize emailHome;
@synthesize emailWork;
@synthesize emailOther;
@synthesize phoneHome;
@synthesize phoneMobile;
@synthesize phoneWork;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Display contact information
    [nameLabel setText:name];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
