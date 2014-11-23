#import <AddressBookUI/AddressBookUI.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>
#import <MessageUI/MessageUI.h>

#import "AppDelegate.h"
#import "Contact.h"
#import "ContactManager.h"
#import "ContactMetadata.h"
#import "ContactViewController.h"

#import "DebugConstants.h"
#import "DebugLogger.h"

@interface ContactViewController () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@end

@implementation ContactViewController

@synthesize contactCard;
@synthesize contactName;
@synthesize contactPhoto;
@synthesize callButton;
@synthesize messageButton;
@synthesize emailButton;

@synthesize contact;
@synthesize firstName;
@synthesize lastName;
@synthesize emailHome;
@synthesize emailWork;
@synthesize emailOther;
@synthesize phoneHome;
@synthesize phoneMobile;
@synthesize phoneWork;
@synthesize callCenter;

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [DebugLogger log:@"Setting up ContactViewController" withPriority:contactViewControllerPriority];
    
    // Get necessary information from contact
    [self setName];
    [self setPhoto];
    [self getNumbers];
    [self getEmails];
    
    // Disable buttons if needed
    if (!phoneHome && !phoneMobile && !phoneWork) {
        [callButton setEnabled:NO];
    }
    if (!phoneMobile || ![MFMessageComposeViewController canSendText]) {
        [messageButton setEnabled:NO];
    }
    if (!emailHome && !emailOther && !emailWork) {
        [emailButton setEnabled:NO];
    }
    
    // Make contact photo ronud
    [[contactPhoto layer] setCornerRadius:contactPhoto.frame.size.width/2];
    [[contactPhoto layer] setMasksToBounds:YES];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                    initWithTarget:self action:@selector(wasTapped:)];
    [contactCard addGestureRecognizer:tapGestureRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissCall) name:CTCallStateDisconnected object:nil];
}

#pragma mark - Getting contact information

- (void)setName {
    NSString *name = [NSString stringWithFormat:@"%@ %@", [contact nameFirst], [contact nameLast]];
    [contactName setText:name];
}

- (void)setPhoto {
    // Get photo (priority: fb, twitter, address book)
    NSData *photoData;
    NSData *facebookPhoto = [contact facebookPhoto];
    NSData *linkedinPhoto = [contact linkedinPhoto];
    if (facebookPhoto != NULL) {
        photoData = facebookPhoto;
    } else if (linkedinPhoto != NULL) {
        photoData = linkedinPhoto;
    } else {
        int abrecordid = [ContactManager verifyABRecordID:[[contact abrecordid] intValue] forContact:contact];
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
        ABRecordRef addressBookContact = ABAddressBookGetPersonWithRecordID(addressBookRef, abrecordid);
        if (ABPersonHasImageData(addressBookContact)) {
            photoData = (__bridge_transfer NSData *)ABPersonCopyImageData(addressBookContact);
            [DebugLogger log:@"Got contact photo" withPriority:mainViewControllerPriority];
        } else {
            UIImage *img = [UIImage imageNamed:@"default_profile_fade0.png"];
            photoData = UIImagePNGRepresentation(img);
            [DebugLogger log:@"No contact photo" withPriority:mainViewControllerPriority];
        }
    }
    [contactPhoto setImage:[[UIImage alloc] initWithData:photoData]];
}

- (void)getNumbers {
    int abrecordid = [ContactManager verifyABRecordID:[[contact abrecordid] intValue] forContact:contact];
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef addressBookContact = ABAddressBookGetPersonWithRecordID(addressBookRef, abrecordid);
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(addressBookContact, kABPersonPhoneProperty);

    NSString *phoneLabel;
    CFStringRef label;
    for (int j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
        // Get label for current phone number
        label = ABMultiValueCopyLabelAtIndex(phoneNumbers, j);
        phoneLabel = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(label);
        
        if ([phoneLabel isEqualToString:@"home"]) {
            phoneHome = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            [DebugLogger log:[NSString stringWithFormat:@"Home Phone: %@", phoneHome] withPriority:mainViewControllerPriority];
        } else if ([phoneLabel isEqualToString:@"mobile"] || [phoneLabel isEqualToString:@"iPhone"]) {
            phoneMobile = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            [DebugLogger log:[NSString stringWithFormat:@"Mobile Phone: %@", phoneMobile] withPriority:mainViewControllerPriority];
        } else if ([phoneLabel isEqualToString:@"work"]) {
            phoneWork = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            [DebugLogger log:[NSString stringWithFormat:@"Work Phone: %@", phoneWork] withPriority:mainViewControllerPriority];
        }
    }
}

- (void)getEmails {
    // Verify contact ID
    int abrecordid = [ContactManager verifyABRecordID:[[contact abrecordid] intValue] forContact:contact];
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef addressBookContact = ABAddressBookGetPersonWithRecordID(addressBookRef, abrecordid);
    ABMultiValueRef emails = ABRecordCopyValue(addressBookContact, kABPersonEmailProperty);
    NSString *emailLabel;
    CFStringRef label;
    for (int j = 0; j < ABMultiValueGetCount(emails); j++) {
        // Get label for current email
        label = ABMultiValueCopyLabelAtIndex(emails, j);
        emailLabel = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(label);
        
        if ([emailLabel isEqualToString:@"home"]) {
            emailHome = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, j);
            [DebugLogger log:[NSString stringWithFormat:@"Home Email: %@", emailHome] withPriority:mainViewControllerPriority];
        } else if ([emailLabel isEqualToString:@"other"]) {
            emailOther = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, j);
            [DebugLogger log:[NSString stringWithFormat:@"Other Email: %@", emailOther] withPriority:mainViewControllerPriority];
        } else if ([emailLabel isEqualToString:@"work"]) {
            emailWork = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, j);
            [DebugLogger log:[NSString stringWithFormat:@"Work Email: %@", emailWork] withPriority:mainViewControllerPriority];
        }
    }
}

#pragma mark - Button Actions

- (IBAction)callButton:(id)sender {
    [DebugLogger log:@"Call button press" withPriority:contactViewControllerPriority];
    if (phoneHome || phoneMobile || phoneWork) {
        [DebugLogger log:@"Has phone number" withPriority:contactViewControllerPriority];
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
            [DebugLogger log:@"Can make call" withPriority:contactViewControllerPriority];

            // Get all numbers
            NSMutableArray *phoneNumbers = [[NSMutableArray alloc] initWithCapacity:3];
            if (phoneHome) {
                [phoneNumbers addObject:phoneHome];
            }
            if (phoneMobile) {
                [phoneNumbers addObject:phoneMobile];
            }
            if (phoneWork) {
                [phoneNumbers addObject:phoneWork];
            }
            
            // Variable number of buttons
            if ([phoneNumbers count] == 1) {
                // Go straight to call
                NSString *number = [phoneNumbers objectAtIndex:0];
                [DebugLogger log:number withPriority:contactViewControllerPriority];
                
                NSString *cleanedString = [[number componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]] componentsJoinedByString:@""];
                NSString *escapedPhoneNumber = [cleanedString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSString *phoneURLString = [NSString stringWithFormat:@"tel:%@", escapedPhoneNumber];
                NSURL *phoneURL = [NSURL URLWithString:phoneURLString];

                // Dismiss view before call (assuming that user does not cancel call)
                [self dismissCall];
                [[UIApplication sharedApplication] openURL:phoneURL];
            } else {
                UIActionSheet *selectNumber = [[UIActionSheet alloc] initWithTitle:phoneActionSheetTitle delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
                int i;
                for (i = 0; i < [phoneNumbers count]; i++) {
                    [selectNumber addButtonWithTitle:[phoneNumbers objectAtIndex:i]];
                }
                [selectNumber addButtonWithTitle:@"Cancel"];
                [selectNumber setCancelButtonIndex:i];
                [selectNumber showInView:[self view]];
            }
        } else {
            [DebugLogger log:@"Cannot make call" withPriority:contactViewControllerPriority];
        }
    }
}

- (IBAction)messageButton:(id)sender {
    [DebugLogger log:@"Message button press" withPriority:contactViewControllerPriority];
    if (phoneMobile != nil) {
        [DebugLogger log:@"Has mobile" withPriority:contactViewControllerPriority];
        if ([MFMessageComposeViewController canSendText]) {
            [DebugLogger log:@"Can send text" withPriority:contactViewControllerPriority];
            [DebugLogger log:phoneMobile withPriority:contactViewControllerPriority];
            NSArray *recipient = @[[NSString stringWithString:phoneMobile]];
            MFMessageComposeViewController *messageViewControler = [[MFMessageComposeViewController alloc] init];
            [messageViewControler setRecipients:recipient];
            messageViewControler.messageComposeDelegate = self;
            [self presentViewController:messageViewControler animated:YES completion:nil];
        }
    }
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

- (IBAction)email:(id)sender {
    [DebugLogger log:@"Email button press" withPriority:contactViewControllerPriority];
    if (emailHome || emailOther || emailWork) {
        [DebugLogger log:@"Has email" withPriority:contactViewControllerPriority];
        if ([MFMailComposeViewController canSendMail]) {
            // Gather emails
            [DebugLogger log:@"Can send email" withPriority:contactViewControllerPriority];
            NSMutableArray *recipient = [[NSMutableArray alloc] initWithCapacity:3];
            if (emailHome) {
                [recipient addObject:emailHome];
            }
            if (emailWork) {
                [recipient addObject:emailWork];
            }
            if (emailOther) {
                [recipient addObject:emailOther];
            }
            
            // Variable number of buttons
            UIActionSheet *selectEmail;
            if ([recipient count] == 1) {
                // Go straight to mail composer
                MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
                [mailViewController setToRecipients:recipient];
                [mailViewController setMailComposeDelegate:self];
                [self presentViewController:mailViewController animated:YES completion:nil];
            } else {
                selectEmail = [[UIActionSheet alloc] initWithTitle:emailActionSheetTitle delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
                int i;
                for (i = 0; i < [recipient count]; i++) {
                    [selectEmail addButtonWithTitle:[recipient objectAtIndex:i]];
                }
                [selectEmail addButtonWithTitle:@"Cancel"];
                [selectEmail setCancelButtonIndex:i];
                [selectEmail showInView:[self view]];
            }
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

// Handle phone number/email selection
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Cancel
    if (buttonIndex == [actionSheet cancelButtonIndex]) {
        return;
    }
    
    // Phone Select
    if ([[actionSheet title] isEqualToString:phoneActionSheetTitle]) {
        NSString *number = [actionSheet buttonTitleAtIndex:buttonIndex];
        NSString *cleanedString = [[number componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]] componentsJoinedByString:@""];
        NSString *escapedPhoneNumber = [cleanedString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *phoneURLString = [NSString stringWithFormat:@"telprompt:%@", escapedPhoneNumber];
        NSURL *phoneURL = [NSURL URLWithString:phoneURLString];
        [[UIApplication sharedApplication] openURL:phoneURL];
    }
    
    // Email select
    else if ([[actionSheet title] isEqualToString:emailActionSheetTitle]) {
        NSArray *recipient = @[[actionSheet buttonTitleAtIndex:buttonIndex]];
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        [mailViewController setToRecipients:recipient];
        [mailViewController setMailComposeDelegate:self];
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
}

#pragma mark - Coredata updating

// Update ContactMetadata before dismissing
- (void)incrementNumberTimesContacted:(NSString *)medium {
    // Set up the fetch request for current contact
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    
    NSDictionary *subVars = @{
                              @"NAMEFIRST": firstName,
                              @"NAMELAST": lastName
                              };
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"ContactNameMatch"substitutionVariables:subVars];
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:[NSString stringWithFormat:@"Error updating num times contacted: %@, %@", error, [error userInfo]] withPriority:contactViewControllerPriority];
        abort();
    }
    
    // If this error message appears, it's time to rethink contact identity
    if ([results count] != 1) {
        [DebugLogger log:@"Multiple contacts with same name!" withPriority:contactViewControllerPriority];
        NSLog(@"%@ %@", firstName, lastName);
        abort();
    }
    
    Contact *contact = [results objectAtIndex:0];
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
    if (contacted) {
        // Alert the MainViewController that the contact was contacted
        [[NSNotificationCenter defaultCenter] postNotificationName:@"contacted" object:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
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
