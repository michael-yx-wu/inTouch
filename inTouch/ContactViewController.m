#import <AddressBookUI/AddressBookUI.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>
#import <MessageUI/MessageUI.h>

#import "AppDelegate.h"
#import "Contact.h"
#import "ContactManager.h"
#import "ContactMetadata.h"
#import "ContactViewController.h"
#import "ImageStrings.h"
#import "NotificationStrings.h"

@interface ContactViewController () {
    __weak IBOutlet UIView *contactButtonsView;
    __weak IBOutlet UIView *manualButtonsView;
}
@end

// Titles and identifier strings specific to this view controller -- not global constants
static NSString *phoneActionSheetTitle = @"Which number to call?";
static NSString *messageActionSheetTitle = @"Which number to text?";
static NSString *emailActionSheetTitle = @"Which email?";
static NSString *contactedCall = @"called";
static NSString *contactedMessage = @"messaged";
static NSString *contactedEmail = @"emailed";
static NSString *contactedGeneric = @"generic";

@implementation ContactViewController

@synthesize contactCard;
@synthesize contactName;
@synthesize contactPhoto;
@synthesize callButton;
@synthesize messageButton;
@synthesize emailButton;
@synthesize contactPhotoCornerRadius;
@synthesize contact;
@synthesize allEmailAddresses;
@synthesize allPhoneNumbers;

@synthesize callCenter;

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [DebugLogger log:@"Setting up ContactViewController" withPriority:contactViewControllerPriority];

    // Reset the dictionaries on each load
    allEmailAddresses = [[NSMutableDictionary alloc] init];
    allPhoneNumbers = [[NSMutableDictionary alloc] init];

    // Get necessary information from contact
    NSString *name = [NSString stringWithFormat:@"%@ %@", [contact nameFirst], [contact nameLast]];
    [contactName setText:name];
    [contactPhoto setImage:[UIImage imageWithData:[contact getPhotoData]]];
    allPhoneNumbers = [contact getPhoneNumbers];
    allEmailAddresses = [contact getEmails];
    
    // Set photo mask
    [[contactPhoto layer] setCornerRadius:contactPhotoCornerRadius];
    [[contactPhoto layer] setMasksToBounds:YES];
    
    // Disable buttons if needed
    if ([allPhoneNumbers count] == 0 || ![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
        [callButton setEnabled:NO];
    }
    if ([allPhoneNumbers count] == 0) {
        [messageButton setEnabled:NO];
    }
    if ([allEmailAddresses count] == 0) {
        [emailButton setEnabled:NO];
    }
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:backgroundImageName]];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                    initWithTarget:self action:@selector(wasTapped:)];
    [contactCard addGestureRecognizer:tapGestureRecognizer];
    
    // Listen for call end notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissCall)
                                                 name:CTCallStateDisconnected
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    // Hide UI elements
    [self hideButtons];
}

- (void)viewDidAppear:(BOOL)animated {
    // Fade in UI elements
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self showButtons];
                     }
                     completion:nil];
}

#pragma mark - Button Actions

// Phone or message button pressed. Show phone numbers for contact
- (IBAction)showNumbers:(id)sender {
    [DebugLogger log:@"Call button pressed" withPriority:contactViewControllerPriority];

    // Alert controller title depends on which button was presses
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    if (sender == callButton) {
        [alertController setTitle:phoneActionSheetTitle];
    } else {
        [alertController setTitle:messageActionSheetTitle];
    }

    // Add all numbers
    NSArray *sortedLabels = [[allPhoneNumbers allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSUInteger i;
    for (i = 0; i < [sortedLabels count]; i++) {
        NSString *numberWithLabel = [NSString stringWithFormat:@"%@: %@",
                                     [sortedLabels objectAtIndex:i],
                                     [allPhoneNumbers valueForKey:[sortedLabels objectAtIndex:i]]];
        UIAlertAction *action = [UIAlertAction actionWithTitle:numberWithLabel
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           NSRange rangeOfColonSpace = [numberWithLabel rangeOfString:@": "];
                                                           NSString *number = [numberWithLabel substringFromIndex:rangeOfColonSpace.location + rangeOfColonSpace.length];
                                                           if (sender == callButton) {
                                                               number = [number stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                                               number = [NSString stringWithFormat:@"telprompt:%@", number];
                                                               NSURL *url = [NSURL URLWithString:number];
                                                               [[UIApplication sharedApplication] openURL:url];
                                                           } else {
                                                               MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
                                                               [messageViewController setRecipients:@[number]];
                                                               [messageViewController setMessageComposeDelegate:self];
                                                               [self presentViewController:messageViewController animated:YES completion:nil];
                                                           }
                                                       }];
        [alertController addAction:action];
    }
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    // Present
    [self presentViewController:alertController animated:YES completion:nil];
}

// Email button pressed. Show emails for contact
- (IBAction)showEmails:(id)sender {
    [DebugLogger log:@"Email button pressed" withPriority:contactViewControllerPriority];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:emailActionSheetTitle
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *sortedLabels = [[allEmailAddresses allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for (NSInteger i = 0; i < [sortedLabels count]; i++) {
        NSString *emailWithLabel = [NSString stringWithFormat:@"%@: %@",
                                    [sortedLabels objectAtIndex:i],
                                    [allEmailAddresses valueForKey:[sortedLabels objectAtIndex:i]]];
        UIAlertAction *action = [UIAlertAction actionWithTitle:emailWithLabel
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           NSRange rangeOfColonSpace = [emailWithLabel rangeOfString:@": "];
                                                           NSString *email = [emailWithLabel substringFromIndex:rangeOfColonSpace.location + rangeOfColonSpace.length];
                                                           NSArray *recipient = @[email];
                                                           MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
                                                           [mailViewController setToRecipients:recipient];
                                                           [mailViewController setMailComposeDelegate:self];
                                                           [self presentViewController:mailViewController animated:YES completion:nil];
                                                       }];
        [alertController addAction:action];
    }
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    // Present
    [self presentViewController:alertController animated:YES completion:nil];
}

// Handle message sent/cancelled events
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult) result {
    [self dismissViewControllerAnimated:YES completion:^{
        switch (result) {
            case MessageComposeResultCancelled: {
                [DebugLogger log:@"Message compose cancelled" withPriority:contactViewControllerPriority];
                break;
            }
            case MessageComposeResultFailed: {
                [DebugLogger log:@"Message failed to send" withPriority:contactViewControllerPriority];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                         message:@"Message failed to send"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
                break;
            }
            case MessageComposeResultSent: {
                [DebugLogger log:@"Message sent!" withPriority:contactViewControllerPriority];
                [(ContactMetadata *)[contact metadata] incrementTimesContacted:contactedByMessage];
                [self dismissViewController:YES];
            }
            default: {
                break;
            }
        }
    }];
}

// Handle email sent/cancelled events
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:^{
        switch (result) {
            case MFMailComposeResultCancelled: {
                [DebugLogger log:@"Email compose cancelled" withPriority:contactViewControllerPriority];
                break;
            }
            case MFMailComposeResultFailed: {
                [DebugLogger log:@"Email failed to save/send" withPriority:contactViewControllerPriority];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                         message:@"Mail failed to send or save"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault
                                                                  handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
                break;
            }
            case MFMailComposeResultSaved: {
                [DebugLogger log:@"Email saved" withPriority:contactViewControllerPriority];
                break;
            }
            case MFMailComposeResultSent: {
                [DebugLogger log:@"Message sent" withPriority:contactViewControllerPriority];
                [(ContactMetadata *)[contact metadata] incrementTimesContacted:contactedByEmail];
                [self dismissViewController:YES];
                break;
            }
            default: {
                break;
            }
        }
    }];
}

#pragma mark - Dismiss methods

- (void)wasTapped:(UITapGestureRecognizer *)tapGestureRecognizer {
    // Tapped picture, dismiss controller
    [self dismissCancel:nil];
}

- (IBAction)dismissCancel:(id)sender {
    // InTouch canceled - no logging
    [self dismissViewController:NO];
}

- (IBAction)dismissContacted:(id)sender {
    // Generic contacted method
    [(ContactMetadata *)[contact metadata] incrementTimesContacted:contactedManually];
    [self dismissViewController:YES];
}

- (void)dismissCall {
    // Record call click before dismissal
    [(ContactMetadata *)[contact metadata] incrementTimesContacted:contactedByCall];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CTCallStateDisconnected object:nil];
    [self dismissViewController:YES];
}

- (void)dismissViewController:(BOOL)contacted {
    // Fade out buttons before dismissing
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self hideButtons];
                     }
                     completion:^(BOOL finished) {
                         [self dismissViewControllerAnimated:NO completion:^{
                             if (contacted) {
                                 // Alert the MainViewController that the contact was contacted
                                 [[NSNotificationCenter defaultCenter] postNotificationName:contactedNotification object:self];
                             }
                         }];
                     }];
}

#pragma mark - UI

- (void)hideButtons {
    [contactButtonsView setAlpha:0];
    [manualButtonsView setAlpha:0];
}

- (void)showButtons {
    [contactButtonsView setAlpha:1];
    [manualButtonsView setAlpha:1];
}

#pragma mark - Core Data Accessor Methods

- (NSManagedObjectContext *)managedObjectContext {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate managedObjectContext];
}

- (NSManagedObjectModel *)managedObjectModel {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate managedObjectModel];
}

@end
