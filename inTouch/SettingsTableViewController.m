#import <MessageUI/MessageUI.h>

#import "AppDelegate.h"
#import "ContactManager.h"
#import "SettingsTableViewController.h"

@interface SettingsTableViewController () <MFMailComposeViewControllerDelegate>
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
        
        // Feedback
        if ([indexPath row] == 4) {
            if ([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
                [mailViewController setToRecipients:@[@"help@intouchapp.io"]];
                [mailViewController setSubject:@"App Feedback"];
                [mailViewController setMailComposeDelegate:self];
                [self presentViewController:mailViewController animated:YES completion:nil];
            } else {
                UIAlertView *cannotSendMailAlert = [[UIAlertView alloc] initWithTitle:@"Cannot Send Feedback"
                                                                              message:@"An email account has not been setup on this device."
                                                                             delegate:self cancelButtonTitle:@"Okay"
                                                                    otherButtonTitles:nil];
                [cannotSendMailAlert show];
            }
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

- (void)facebookLogin {
    // If session state is open then close the session and remove access token from cache
    if ([[FBSession activeSession] state] == FBSessionStateOpen ||
        [[FBSession activeSession] state] == FBSessionStateOpenTokenExtended) {
        [[FBSession activeSession] closeAndClearTokenInformation];
    }
    // If session state is closed then open session showing the login UI.
    else {
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
//                                          [[UIApplication sharedApplication] delegate]
                                      }];
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
        [UIView animateWithDuration:1.0 delay:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            // Hide activity indicator
            [syncingContactsActivityIndicator setAlpha:0];
        } completion:^(BOOL finished) {
            // Stop activity indicator and renable user interaction
            [syncingContactsActivityIndicator stopAnimating];
            [[self view] setUserInteractionEnabled:YES];
        }];
    }];
}

// Handle email sent/cancelled events
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    switch (result) {
        case MFMailComposeResultCancelled: {
            [DebugLogger log:@"Feedback cancelled" withPriority:contactViewControllerPriority];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case MFMailComposeResultFailed: {
            [DebugLogger log:@"Feedback failed to save/send" withPriority:contactViewControllerPriority];
            break;
        }
        case MFMailComposeResultSaved: {
            [DebugLogger log:@"Feedback saved" withPriority:contactViewControllerPriority];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case MFMailComposeResultSent: {
            [DebugLogger log:@"Feedback sent" withPriority:contactViewControllerPriority];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        default:
            break;
    }
}

@end
