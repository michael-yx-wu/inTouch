#import <AddressBookUI/AddressBookUI.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>
#import <MessageUI/MessageUI.h>

#import "AppDelegate.h"
#import "Contact.h"
#import "ContactManager.h"
#import "ContactMetadata.h"
#import "ContactViewController.h"
#import "NotificationStrings.h"

@interface ContactViewController () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

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
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                    initWithTarget:self action:@selector(wasTapped:)];
    [contactCard addGestureRecognizer:tapGestureRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissCall) name:CTCallStateDisconnected object:nil];
}

// Set mask only after view appears because it is screen width dependent
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Make contact photo round
    [[contactPhoto layer] setCornerRadius:contactPhoto.frame.size.width/2];
    [[contactPhoto layer] setMasksToBounds:YES];
    [contactPhoto setAlpha:1];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Hide photo until we round it
    [contactPhoto setAlpha:0];
}

#pragma mark - Button Actions

// Phone or message button pressed. Show UIActionSheet with phone numbers for contact
- (IBAction)showNumbers:(id)sender {
    [DebugLogger log:@"Call button pressed" withPriority:contactViewControllerPriority];

    // Set action sheet title based on sender
    UIActionSheet *selectNumber;
    if (sender == callButton) {
        selectNumber = [[UIActionSheet alloc] initWithTitle:phoneActionSheetTitle
                                                   delegate:self
                                          cancelButtonTitle:nil
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:nil];
    } else if (sender == messageButton) {
        selectNumber = [[UIActionSheet alloc] initWithTitle:messageActionSheetTitle
                                                   delegate:self
                                          cancelButtonTitle:nil
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:nil];
    }
    
    // Add all numbers to action sheet
    NSArray *sortedLabels = [[allPhoneNumbers allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSUInteger i;
    for (i = 0; i < [sortedLabels count]; i++) {
        NSString *numberWithLabel = [NSString stringWithFormat:@"%@: %@",
                                     [sortedLabels objectAtIndex:i],
                                     [allPhoneNumbers valueForKey:[sortedLabels objectAtIndex:i]]];
        [selectNumber addButtonWithTitle:numberWithLabel];
    }
    
    // Add the cancel button at the bottom
    [selectNumber addButtonWithTitle:@"Cancel"];
    [selectNumber setCancelButtonIndex:i];
    
    // Show action sheet
    [selectNumber showInView:[self view]];
}

// Email button pressed. Show UIActionSheet with emails for contact
- (IBAction)showEmails:(id)sender {
    [DebugLogger log:@"Email button pressed" withPriority:contactViewControllerPriority];
    
    // Set action sheet title based on sender
    UIActionSheet *selectEmail;
    selectEmail = [[UIActionSheet alloc] initWithTitle:emailActionSheetTitle
                                               delegate:self
                                      cancelButtonTitle:nil
                                 destructiveButtonTitle:nil
                                      otherButtonTitles:nil];
    
    // Add all numbers to action sheet
    NSArray *sortedLabels = [[allEmailAddresses allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSUInteger i;
    for (i = 0; i < [sortedLabels count]; i++) {
        NSString *emailWithLabel = [NSString stringWithFormat:@"%@: %@",
                                     [sortedLabels objectAtIndex:i],
                                     [allEmailAddresses valueForKey:[sortedLabels objectAtIndex:i]]];
        [selectEmail addButtonWithTitle:emailWithLabel];
    }
    
    // Add the cancel button at the bottom
    [selectEmail addButtonWithTitle:@"Cancel"];
    [selectEmail setCancelButtonIndex:i];
    
    // Show action sheet
    [selectEmail showInView:[self view]];
}

// Handle message sent/cancelled events
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result {
    switch (result) {
        case MessageComposeResultCancelled: {
            [DebugLogger log:@"Message compose cancelled" withPriority:contactViewControllerPriority];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case MessageComposeResultFailed: {
            [DebugLogger log:@"Message failed to send" withPriority:contactViewControllerPriority];
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Messaged failed to send!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case MessageComposeResultSent: {
            [DebugLogger log:@"Message sent!" withPriority:contactViewControllerPriority];
            [self dismissViewControllerAnimated:YES completion:nil];
            [self performSelector:@selector(dismissMessage) withObject:nil afterDelay:1];
        }
        default: {
            break;
        }
    }
}

// Handle email sent/cancelled events
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    switch (result) {
        case MFMailComposeResultCancelled: {
            [DebugLogger log:@"Email compose cancelled" withPriority:contactViewControllerPriority];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case MFMailComposeResultFailed: {
            [DebugLogger log:@"Email failed to save/send" withPriority:contactViewControllerPriority];
            break;
        }
        case MFMailComposeResultSaved: {
            [DebugLogger log:@"Email saved" withPriority:contactViewControllerPriority];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case MFMailComposeResultSent: {
            [DebugLogger log:@"Message sent" withPriority:contactViewControllerPriority];
            [self dismissViewControllerAnimated:YES completion:nil];
            [self performSelector:@selector(dismissEmail) withObject:nil afterDelay:1];
            break;
        }
        default:
            break;
    }
}

// Handle phone number/email selection from UIActionSheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Cancel
    if (buttonIndex == [actionSheet cancelButtonIndex]) {
        return;
    }
    
    NSString *numberOrEmail = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSRange rangeOfColonSpace = [numberOrEmail rangeOfString:@": "];
    numberOrEmail = [numberOrEmail substringFromIndex:rangeOfColonSpace.location + rangeOfColonSpace.length];
    
    // Phone Select
    if ([[actionSheet title] isEqualToString:phoneActionSheetTitle]) {
        // Create the phone URL before passing it off
        numberOrEmail = [[numberOrEmail componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]] componentsJoinedByString:@""];
        numberOrEmail = [numberOrEmail stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *phoneURLString = [NSString stringWithFormat:@"telprompt:%@", numberOrEmail];
        NSURL *phoneURL = [NSURL URLWithString:phoneURLString];
        [[UIApplication sharedApplication] openURL:phoneURL];
    }
    
    // Message Select
    else if ([[actionSheet title] isEqualToString:messageActionSheetTitle]) {
        NSArray *recipient = @[numberOrEmail];
        MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
        [messageViewController setRecipients:recipient];
        [messageViewController setMessageComposeDelegate:self];
        [self presentViewController:messageViewController animated:YES completion:nil];
    }
    
    // Email select
    else if ([[actionSheet title] isEqualToString:emailActionSheetTitle]) {
        NSArray *recipient = @[numberOrEmail];
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        [mailViewController setToRecipients:recipient];
        [mailViewController setMailComposeDelegate:self];
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
}

#pragma mark - Coredata updating

// Update ContactMetadata before dismissing
- (void)incrementNumberTimesContacted:(NSString *)medium {
    ContactMetadata *metadata = (ContactMetadata *)[contact metadata];
    
    // Get timesContacted info
    NSNumber *numTimesContacted, *numTimesCalled, *numTimesMessaged, *numTimesEmailed, *timesContacted;
    numTimesContacted = [metadata numTimesContacted];
    numTimesCalled = [metadata numTimesCalled];
    numTimesMessaged = [metadata numTimesMessaged];
    numTimesEmailed = [metadata numTimesEmailed];
    
    // Increment times contacted
    timesContacted = [NSNumber numberWithInt:[numTimesContacted intValue]+1];
    [metadata setNumTimesContacted:timesContacted];
    [DebugLogger log:[NSString stringWithFormat:@"Times contacted: %d", [timesContacted intValue]] withPriority:contactViewControllerPriority];
    
    // Increment times contacted based on medium
    if ([medium isEqualToString:contactedCall]) {
        timesContacted = [NSNumber numberWithInt:[numTimesCalled intValue]+1];
        [metadata setNumTimesCalled:timesContacted];
        [DebugLogger log:[NSString stringWithFormat:@"Times called: %d", [timesContacted intValue]] withPriority:contactViewControllerPriority];
    } else if ([medium isEqualToString:contactedMessage]) {
        timesContacted = [NSNumber numberWithInt:[numTimesMessaged intValue]+1];
        [metadata setNumTimesMessaged:timesContacted];
        [DebugLogger log:[NSString stringWithFormat:@"Times messaged: %d", [timesContacted intValue]] withPriority:contactViewControllerPriority];
    } else if ([medium isEqualToString:contactedEmail]) {
        timesContacted = [NSNumber numberWithInt:[numTimesEmailed intValue]+1];
        [metadata setNumTimesEmailed:timesContacted];
        [DebugLogger log:[NSString stringWithFormat:@"Times emailed: %d", [timesContacted intValue]] withPriority:contactViewControllerPriority];
    } else if (![medium isEqualToString:contactedGeneric]){
        [DebugLogger log:@"Error updating contact method frequency... please check spelling!" withPriority:contactViewControllerPriority];
    }

    // Set last contact date
    NSDate *today = [NSDate date];
    [metadata setLastContactedDate:today];
}

#pragma mark - Dismiss methods

- (void)wasTapped:(UITapGestureRecognizer *)tapGestureRecognizer {
    // Tapped picture, dismiss controller
    NSLog(@"tapped");
    [self dismissCancel:nil];
}

- (IBAction)dismissCancel:(id)sender {
    // InTouch canceled - no logging
    [self dismissViewController:NO];
}

- (IBAction)dismissContacted:(id)sender {
    // Generic contacted method
    [self incrementNumberTimesContacted:contactedGeneric];
    [self dismissViewController:YES];
}

- (void)dismissCall {
    // Record call click before dismissal
    [self incrementNumberTimesContacted:contactedCall];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CTCallStateDisconnected object:nil];
    [self dismissViewController:YES];
}

- (void)dismissMessage {
    // Record message click before dismissal
    [self incrementNumberTimesContacted:contactedMessage];
    [self dismissViewController:YES];
}

- (void)dismissEmail {
    // Record email click before dismissal
    [self incrementNumberTimesContacted:contactedEmail];
    [self dismissViewController:YES];
}

- (void)dismissViewController:(BOOL)contacted {
    [self dismissViewControllerAnimated:NO completion:^{
        if (contacted) {
            // Alert the MainViewController that the contact was contacted
            [[NSNotificationCenter defaultCenter] postNotificationName:contactedNotification object:self];
        }
    }];
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
