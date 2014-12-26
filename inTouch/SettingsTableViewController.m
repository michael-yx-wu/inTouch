#import <MessageUI/MessageUI.h>

#import "AppDelegate.h"
#import "ContactManager.h"
#import "FacebookManager.h"
#import "NotificationStrings.h"
#import "SettingsTableViewController.h"

@interface SettingsTableViewController () <MFMailComposeViewControllerDelegate>
@end

@implementation SettingsTableViewController

@synthesize facebookCell;
@synthesize facebookCellDetailLabel;

@synthesize syncingContactsActivityIndicator;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Listen for fb session state changed notifications from app delegate
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFacebookNameLabel)
                                                 name:facebookSessionStateChanged
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateFacebookNameLabel];
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
        // Sync contacts
        if ([indexPath row] == 2) {
            [self syncContacts];
        }
        
        // Feedback
        else if ([indexPath row] == 3) {
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
            [self facebookButton];
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

#pragma mark - Facebook

// Handle facebook cell press -- masquerading as a button
- (void)facebookButton {
    UIAlertController *alertController;
    UIAlertAction *cancel;
    UIAlertAction *okay;
    
    // Prompt user with brief message before connecting/disconnecting facebook account
    if ([FacebookManager sessionOpen]) {
        alertController = [UIAlertController alertControllerWithTitle:@"Disconnect account?"
                                                              message:@"If you disconnect your Facebook account, we will no longer be able to use the latest contact profile pictures from Facebook."
                                                       preferredStyle:UIAlertControllerStyleAlert];
        cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                          style:UIAlertActionStyleCancel
                                        handler:^(UIAlertAction *action) {
                                        }];
        okay = [UIAlertAction actionWithTitle:@"Disconnect"
                                        style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction *action) {
                                          [FacebookManager logout];
                                      }];
    } else {
        alertController = [UIAlertController alertControllerWithTitle:@"Connect to Facebook?"
                                                              message:@"Connecting your Facebook account will allow us to use Facebook profile pictures for your contacts."
                                                       preferredStyle:UIAlertControllerStyleAlert];
        cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                          style:UIAlertActionStyleCancel
                                        handler:^(UIAlertAction *action) {
                                        }];
        okay = [UIAlertAction actionWithTitle:@"Connect"
                                        style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction *action) {
                                          [FacebookManager login];
                                      }];
    }
    
    // Show the message
    [alertController addAction:cancel];
    [alertController addAction:okay];
    [self presentViewController:alertController animated:YES completion:nil];
}

// This is called when the session state changes and every time the view is about to be shown
- (void)updateFacebookNameLabel {
    // If we are logged in, set the user name
    if ([[FBSession activeSession] state] == FBSessionStateOpen ||
        [[FBSession activeSession] state] == FBSessionStateOpenTokenExtended) {
        [facebookCell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [facebookCellDetailLabel setText:@"Connected"];
    } else {
        [facebookCell setAccessoryType:UITableViewCellAccessoryNone];
        [facebookCellDetailLabel setText:@"Not Connected"];
    }
}

@end
