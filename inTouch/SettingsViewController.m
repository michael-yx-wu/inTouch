#import "ContactManager.h"
#import "SettingsViewController.h"

#import "DebugConstants.h"
#import "DebugLogger.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize busyView;
@synthesize activityIndicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Load in background image
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)dismissCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NO];
}

- (IBAction)dismissSave:(id)sender {
    // save the settings
    [self dismissViewControllerAnimated:YES completion:NO];
}

// Display the "syncing contacts" message and sync contacts
- (IBAction)syncContacts:(id)sender {
    // Show the busy view
    [DebugLogger log:@"Showing busy view" withPriority:settingsViewControllerPriority];
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [[self view] setUserInteractionEnabled:NO];
        [busyView setAlpha:1];
        [activityIndicator startAnimating];
    } completion:^(BOOL finished) {
        [ContactManager updateInformation];
        [ContactManager updateUrgency];
        [UIView animateWithDuration:0.3 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [busyView setAlpha:0];
        } completion:^(BOOL finished){
            [activityIndicator stopAnimating];
            [[self view] setUserInteractionEnabled:YES];
        }];
    }];
}

@end
