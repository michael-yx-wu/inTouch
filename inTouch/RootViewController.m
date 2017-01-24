#import "RootViewController.h"

#import "AppDelegate.h"
#import "GlobalData.h"
#import "NotificationStrings.h"
#import "MainViewController.h"

@implementation RootViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
    /* Should we ever need a login view, this is where we would conditionally display it */

    [self performSegueWithIdentifier:@"mainView" sender:self];
}

@end
