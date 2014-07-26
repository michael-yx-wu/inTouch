#import "ContactManager.h"
#import "SettingsTableViewController.h"

#import "DebugConstants.h"
#import "DebugLogger.h"

@interface SettingsTableViewController ()
@end

@implementation SettingsTableViewController

@synthesize syncingContactsActivityIndicator;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// Dismiss settings view
- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Deselect index path
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Section 0
    if ([indexPath section] == 0) {
        // Display help
        if ([indexPath row] == 0) {
            [self performSegueWithIdentifier:@"help" sender:self];
        }
        
        // Edit contacts
        if ([indexPath row] == 2) {
            [self performSegueWithIdentifier:@"editContacts" sender:self];
        }
        
        // Sync contacts
        if ([indexPath row] == 3) {
            [self syncContacts];
        }
        
    }
    
    // Section 1 - Social Network Login
    else if ([indexPath section] == 1) {
        // Display facebook login page
        if ([indexPath row] == 0) {
            [self performSegueWithIdentifier:@"facebook" sender:self];
        }
    }
}

// Sync contacts and show busy indicator
- (void)syncContacts {
    [DebugLogger log:@"Syncing Contacts" withPriority:settingsTableViewControllerPriority];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        // Disable interaction while syncing
        [[self view] setUserInteractionEnabled:NO];
        
        // Start spinning activity indicator
        [syncingContactsActivityIndicator startAnimating];
        [syncingContactsActivityIndicator setAlpha:1];
    } completion:^(BOOL finished) {
        [ContactManager updateInformation];
        [ContactManager updateUrgency];
        [UIView animateWithDuration:1.0 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            // Hide activity indicator
            [syncingContactsActivityIndicator setAlpha:0];
        } completion:^(BOOL finished) {
            // Stop activity indicator and renable user interaction
            [syncingContactsActivityIndicator stopAnimating];
            [[self view] setUserInteractionEnabled:YES];
        }];
    }];
}

@end
