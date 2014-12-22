#import <MessageUI/MessageUI.h>

#import "AppDelegate.h"
#import "ContactManager.h"
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
                                                 name:@"fbSessionStateChanged"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
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
        // Display help
        if ([indexPath row] == 0) {
            [self performSegueWithIdentifier:@"help" sender:self];
        }
        
        // Edit contacts
        if ([indexPath row] == 1) {
            [self performSegueWithIdentifier:@"editContacts" sender:self];
        }
        
        // Sync contacts
        if ([indexPath row] == 2) {
            [self syncContacts];
        }
        
        // Feedback
        if ([indexPath row] == 3) {
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
            [self facebookLogin];
        }
    }
}

// Attempt a login using the Facebook app. Fall back to Safari web form if not available
- (void)facebookLogin {
    // If session state is open then close the session and remove access token from cache
    if ([[FBSession activeSession] state] == FBSessionStateOpen ||
        [[FBSession activeSession] state] == FBSessionStateOpenTokenExtended) {
        // Prompt user if it's okay to log out
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Disconnect account?"
                                                                                 message:@"If you disconnect your Facebook account from InTouch, we will no longer be able to pull contact profile pictures from Facebook."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction *action) {
                                                       }];
        UIAlertAction *disconnect = [UIAlertAction actionWithTitle:@"Disconnect"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               [[FBSession activeSession] closeAndClearTokenInformation];
                                                           }];
        [alertController addAction:cancel];
        [alertController addAction:disconnect];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    // If session state is closed then open session showing the login UI.
    else {
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                          AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
                                          [delegate sessionStateChanged:session state:status error:error];
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

#pragma mark - Facebook

// This is called when the session state changes and every time the view is about to be shown
- (void)updateFacebookNameLabel {
    // If we are logged in, set the user name
    if ([[FBSession activeSession] state] == FBSessionStateOpen ||
        [[FBSession activeSession] state] == FBSessionStateOpenTokenExtended) {
        [facebookCell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [facebookCellDetailLabel setText:@"Connected"];
        
        // Update the user's facebook friends list
        [self getFacebookFriends];
    } else {
        [facebookCell setAccessoryType:UITableViewCellAccessoryNone];
        [facebookCellDetailLabel setText:@"Not Connected"];
    }
}

// Populate fbFriends with facebook friend names and url - this is so ugly right now (indentation is killing me)
- (void)getFacebookFriends {
    [FBRequestConnection startWithGraphPath:@"/me/taggable_friends?fields=name,picture.width(400).height(400)"
                          completionHandler:^(FBRequestConnection *connection,
                                              id result, NSError
                                              *error) {
                              NSMutableDictionary *fbFriends = [[NSMutableDictionary alloc] init];
                              if (error) {
                                  [DebugLogger log:[NSString stringWithFormat:@"request error: %@", [error userInfo]]
                                      withPriority:contactManagerPriority];
                              }
                              // Process facebook json object
                              NSArray *taggableFriends = [result objectForKey:@"data"];
                              for (NSDictionary *friend in taggableFriends) {
                                  NSString *name = [friend valueForKey:@"name"];
                                  NSArray *url = [[[friend valueForKey:@"picture"] valueForKey:@"data"]
                                                  valueForKey:@"url"];
                                  [fbFriends setValue:url forKey:name];
                              }
                              
                              // Post notification for MainViewController
                              NSDictionary *notificationData = @{@"data": fbFriends};
                              [[NSNotificationCenter defaultCenter] postNotificationName:@"facebookFriends"
                                                                                  object:self
                                                                                userInfo:notificationData];
                          }];
    
}

@end
