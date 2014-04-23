//
//  ContactViewController.m
//  inTouch
//
//  Created by Michael Wu on 3/24/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

#import <CoreTelephony/CTCall.h>
#import <MessageUI/MessageUI.h>

#import "AppDelegate.h"
#import "ContactViewController.h"
#import "UrgencyCalculator.h"

#import "DebugLogger.h"

@interface ContactViewController () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@end

@implementation ContactViewController

@synthesize contactName;
@synthesize contactPhoto;
@synthesize lastContactedLabel;
@synthesize callButton;
@synthesize messageButton;
@synthesize emailButton;

@synthesize firstName;
@synthesize lastName;
@synthesize photoData;
@synthesize lastContactedString;
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
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [DebugLogger log:@"Setting up ContactViewController" withPriority:3];
    
    // Display contact information
    NSString *name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    [contactName setText:name];
    if (photoData) {
        [contactPhoto setImage:photoData];
    }
    [lastContactedLabel setText:lastContactedString];
    
    // Disable buttons if needed
    if ((!phoneHome && !phoneMobile && !phoneWork) || ![MFMessageComposeViewController canSendText]) {
        [callButton setEnabled:NO];
    }
    if (!phoneMobile || ![MFMessageComposeViewController canSendText]) {
        [messageButton setEnabled:NO];
    }
    if (!emailHome && !emailOther && !emailWork) {
        [emailButton setEnabled:NO];
    }
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    
    // Set a listener for end calls
    [self listenForCallEnds];
}

#pragma mark - Button Actions

- (IBAction)callButton:(id)sender {
    [DebugLogger log:@"Call button press" withPriority:3];
    if (phoneHome || phoneMobile || phoneWork) {
        [DebugLogger log:@"Has phone number" withPriority:3];
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
            [DebugLogger log:@"Can make call" withPriority:3];

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
            
            // Creat the message string
            NSMutableString *selectString = [[NSMutableString alloc] init];
            for (int i = 0; i < [phoneNumbers count]; i++) {
                [selectString appendString:[NSString stringWithFormat:@"%d. %@ ", i+1, [phoneNumbers objectAtIndex:i]]];
                if (i != [phoneNumbers count]-1) {
                    [selectString appendString:@"\n"];
                }
            }
            
            // Variable number of buttons
            if ([phoneNumbers count] == 1) {
                // Go straight to call
                NSString *number = [phoneNumbers objectAtIndex:0];
                NSString *url = [NSString stringWithFormat:@"telprompt://%@", number];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
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
            [DebugLogger log:@"Cannot make call" withPriority:3];
        }
    }
}

- (IBAction)messageButton:(id)sender {
    [DebugLogger log:@"Message button press" withPriority:3];
    if (phoneMobile != nil) {
        [DebugLogger log:@"Has mobile" withPriority:3];
        if ([MFMessageComposeViewController canSendText]) {
            [DebugLogger log:@"Can send text" withPriority:3];
            [DebugLogger log:phoneMobile withPriority:3];
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
            [DebugLogger log:@"Message compose cancelled" withPriority:3];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case MessageComposeResultFailed: {
            [DebugLogger log:@"Message failed to send" withPriority:3];
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Messaged failed to send!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case MessageComposeResultSent: {
            [DebugLogger log:@"Message sent!" withPriority:3];
            [self dismissViewControllerAnimated:YES completion:nil];
            [self performSelector:@selector(dismissMessage) withObject:nil afterDelay:1];
        }
        default: {
            break;
        }
    }
}

- (IBAction)email:(id)sender {
    [DebugLogger log:@"Email button press" withPriority:3];
    if (emailHome || emailOther || emailWork) {
        [DebugLogger log:@"Has email" withPriority:3];
        if ([MFMailComposeViewController canSendMail]) {
            // Gather emails
            [DebugLogger log:@"Can send email" withPriority:3];
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
            
            // Create the message string
            NSMutableString *emails = [[NSMutableString alloc] init];
            for (int i = 0; i < [recipient count]; i++) {
                [emails appendString:[NSString stringWithFormat:@"%d. %@ ", i+1, [recipient objectAtIndex:i]]];
                if (i != [recipient count]-1) {
                    [emails appendString:@"\n"];
                }
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
            [DebugLogger log:@"Email compose cancelled" withPriority:3];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case MFMailComposeResultFailed: {
            [DebugLogger log:@"Email failed to save/send" withPriority:3];
            break;
        }
        case MFMailComposeResultSaved: {
            [DebugLogger log:@"Email saved" withPriority:3];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case MFMailComposeResultSent: {
            [DebugLogger log:@"Message sent" withPriority:3];
            [self dismissViewControllerAnimated:YES completion:nil];
            [self performSelector:@selector(dismissEmail) withObject:nil afterDelay:1];
            break;
        }
        default:
            break;
    }
}

- (IBAction)manuallyContacted:(id)sender {
    
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
        NSString *url = [NSString stringWithFormat:@"telprompt://%@", number];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
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
        [DebugLogger log:[NSString stringWithFormat:@"Error updating num times contacted: %@, %@", error, [error userInfo]] withPriority:3];
        abort();
    }
    
    // If this error message appears, it's time to rethink contact identity
    if ([results count] != 1) {
        [DebugLogger log:@"Multiple contacts with same name!" withPriority:3];
        NSLog(@"%@ %@", firstName, lastName);
        abort();
    }
    
    // Get timesContacted info
    NSManagedObject *contact = [results objectAtIndex:0];
    NSManagedObject *contactMetaData = [contact valueForKey:@"metadata"];
    
    NSNumber *numTimesContacted, *numTimesCalled, *numTimesMessaged, *numTimesEmailed, *timesContacted;
    numTimesContacted = [contactMetaData valueForKey:@"numTimesContacted"];
    numTimesCalled = [contactMetaData valueForKey:@"numTimesCalled"];
    numTimesMessaged = [contactMetaData valueForKey:@"numTimesMessaged"];
    numTimesEmailed = [contactMetaData valueForKey:@"numTimesEmailed"];
    
    // Increment times contacted
    timesContacted = [NSNumber numberWithInt:[numTimesContacted intValue]+1];
    [contactMetaData setValue:timesContacted forKey:@"numTimesContacted"];
    [DebugLogger log:[NSString stringWithFormat:@"Times contacted: %d", [timesContacted intValue]] withPriority:3];
    
    // Increment times contacted based on medium
    if ([medium isEqualToString:contactedCall]) {
        timesContacted = [NSNumber numberWithInt:[numTimesCalled intValue] +1];
        [contactMetaData setValue:timesContacted forKeyPath:@"numTimesCalled"];
        [DebugLogger log:[NSString stringWithFormat:@"Times called: %d", [timesContacted intValue]] withPriority:3];
    } else if ([medium isEqualToString:contactedMessage]) {
        timesContacted = [NSNumber numberWithInt:[numTimesMessaged intValue]+1];
        [contactMetaData setValue:timesContacted forKeyPath:@"numTimesMessaged"];
        [DebugLogger log:[NSString stringWithFormat:@"Times messaged: %d", [timesContacted intValue]] withPriority:3];
    } else if ([medium isEqualToString:contactedEmail]) {
        timesContacted = [NSNumber numberWithInt:[numTimesEmailed intValue]+1];
        [contactMetaData setValue:timesContacted forKeyPath:@"numTimesEmailed"];
        [DebugLogger log:[NSString stringWithFormat:@"Times emailed: %d", [timesContacted intValue]] withPriority:3];
    } else if (![medium isEqualToString:contactedGeneric]){
        [DebugLogger log:@"Error updating contact method frequency... please check spelling!" withPriority:3];
    }

    // Set last contact date
    [contactMetaData setValue:[NSDate date] forKeyPath:@"lastContactedDate"];
    
    // Update urgency for this contact only
    [UrgencyCalculator updateUrgencyFirstName:firstName lastName:lastName];
}

#pragma mark - Dismiss methods

- (IBAction)dismissCancel:(id)sender {
    // InTouch canceled - no logging
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)dismissContacted:(id)sender {
    // Generic contacted method
    [self incrementNumberTimesContacted:contactedGeneric];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissCall {
    // Record call click before dismissal
    [self incrementNumberTimesContacted:contactedCall];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissMessage {
    // Record message click before dismissal
    [self incrementNumberTimesContacted:contactedMessage];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissEmail {
    // Record email click before dismissal
    [self incrementNumberTimesContacted:contactedEmail];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper methods

// Fetch Contact entity from coredata based on nanme
- (NSArray *)fetchContact {
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    NSDictionary *subVars = @{
                              @"NAMEFIRST": firstName,
                              @"NAMELAST": lastName
                              };
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"ContactNameMatch"
                                                substitutionVariables:subVars];
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:[NSString stringWithFormat:@"Fetch error: %@, %@",
                          error, [error userInfo]] withPriority:1];
        abort();
    }
    return results;
}

- (void)listenForCallEnds {
    __weak typeof(self) weakSelf = self;
    callCenter = [[CTCallCenter alloc] init];
    [callCenter setCallEventHandler:^(CTCall *call) {
        NSString *callState = [call callState];
        if ([callState isEqualToString:CTCallStateDisconnected]) {
            [weakSelf dismissCall];
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
