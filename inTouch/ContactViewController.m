//
//  ContactViewController.m
//  inTouch
//
//  Created by Michael Wu on 3/24/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

#import <MessageUI/MessageUI.h>

#import "AppDelegate.h"
#import "ContactViewController.h"
#import "UrgencyCalculator.h"

#import "DebugLogger.h"

@interface ContactViewController () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

@end

@implementation ContactViewController

@synthesize contactName;
@synthesize contactPhoto;
@synthesize firstName;
@synthesize lastName;
@synthesize photoData;
@synthesize emailHome;
@synthesize emailWork;
@synthesize emailOther;
@synthesize phoneHome;
@synthesize phoneMobile;
@synthesize phoneWork;

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
    [contactPhoto setImage:photoData];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
}

#pragma mark - Button Actions

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
    } else {
        // Dispay no mobile number
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
    [DebugLogger log:emailHome withPriority:3];
    [DebugLogger log:emailOther withPriority:3];
    [DebugLogger log:emailWork withPriority:3];
    if (emailHome || emailOther || emailWork) {
        [DebugLogger log:@"Has email" withPriority:3];
        if ([MFMailComposeViewController canSendMail]) {
            [DebugLogger log:@"Can send email" withPriority:3];
            [DebugLogger log:phoneMobile withPriority:3];
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
                [emails appendString:[NSString stringWithFormat:@"%d. %@", i+1, [recipient objectAtIndex:i]]];
                if (i != [recipient count]-1) {
                    [emails appendString:@"\n"];
                }
            }
            
            // Variable number of buttons
            UIAlertView *selectEmail;
            if ([recipient count] == 1) {
                // Go straight to mail composer
                MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
                [mailViewController setToRecipients:recipient];
                [mailViewController setMailComposeDelegate:self];
                [self presentViewController:mailViewController animated:YES completion:nil];
            } else if ([recipient count]) {
                selectEmail = [[UIAlertView alloc] initWithTitle:@"Which Email?" message:emails delegate:self cancelButtonTitle:@"1" otherButtonTitles:@"2", nil];
                [selectEmail show];
            } else {
                selectEmail = [[UIAlertView alloc] initWithTitle:@"Which Email" message:emails delegate:self cancelButtonTitle:@"1" otherButtonTitles:@"2", @"3", nil];
                [selectEmail show];
            }
        }
    } else {
        // Dispay no email
    }
}

// Handle email/call select for multiple emails/phone numbers
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *message = [alertView message];
    NSMutableArray *recipients = (NSMutableArray *)[message componentsSeparatedByString:@". "];
    
    // Gather and delete unnecessary components
    NSMutableArray *toDelete = [[NSMutableArray alloc] initWithCapacity:3];
    for (int i = 0; i < [recipients count]; i++) {
        if ([((NSString *)[recipients objectAtIndex:i]) length] == 2) {
            [toDelete addObject:[recipients objectAtIndex:i]];
        }
    }
    for (int i = 0; i < [toDelete count]; i++) {
        [recipients delete:[toDelete objectAtIndex:i]];
    }
    
    // Emails AlertView
    if ([[alertView title] isEqualToString:@"Which Email?"]) {
        NSArray *recipient = @[[recipients objectAtIndex:buttonIndex]];
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        [mailViewController setToRecipients:recipient];
        [mailViewController setMailComposeDelegate:self];
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
    
    // Phones AlertView
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
//    switch (result) {
//        case MessageComposeResultCancelled: {
//            [DebugLogger log:@"Message compose cancelled" withPriority:3];
//            [self dismissViewControllerAnimated:YES completion:nil];
//            break;
//        }
//        case MessageComposeResultFailed: {
//            [DebugLogger log:@"Message failed to send" withPriority:3];
//            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Messaged failed to send!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//            [warningAlert show];
//            [self dismissViewControllerAnimated:YES completion:nil];
//            break;
//        }
//        case MessageComposeResultSent: {
//            [DebugLogger log:@"Message sent!" withPriority:3];
//            [self dismissViewControllerAnimated:YES completion:nil];
//            [self performSelector:@selector(dismissMessage) withObject:nil afterDelay:1];
//        }
//        default: {
//            break;
//        }
//    }
}

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex

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
    
    // Increment times contacted based on medium
    if ([medium isEqualToString:@"call"]) {
        timesContacted = [NSNumber numberWithInt:[numTimesCalled intValue] +1];
        [contactMetaData setValue:timesContacted forKeyPath:@"numTimesCalled"];
        [DebugLogger log:[NSString stringWithFormat:@"Times called: %d", [timesContacted intValue]] withPriority:3];
    } else if ([medium isEqualToString:@"message"]) {
        timesContacted = [NSNumber numberWithInt:[numTimesMessaged intValue]+1];
        [contactMetaData setValue:timesContacted forKeyPath:@"numTimesMessaged"];
        [DebugLogger log:[NSString stringWithFormat:@"Times messaged: %d", [timesContacted intValue]] withPriority:3];
    } else if ([medium isEqualToString:@"email"]) {
        timesContacted = [NSNumber numberWithInt:[numTimesEmailed intValue]+1];
        [contactMetaData setValue:timesContacted forKeyPath:@"numTimesEmailed"];
        [DebugLogger log:[NSString stringWithFormat:@"Times emailed: %d", [timesContacted intValue]] withPriority:3];
    } else {
        [DebugLogger log:@"Error updating contact method frequency... please check spelling!" withPriority:3];
    }
    
    // Set last contact date
    [contactMetaData setValue:[NSDate date] forKeyPath:@"lastContactedDate"];
    
    // Update urgency for this contact only
    [UrgencyCalculator updateUrgencyFirstName:firstName lastName:lastName];
}

#pragma mark - Dismiss methods

- (IBAction)dismiss:(id)sender {
    // InTouch canceled - no logging
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)dismissCall:(id)sender {
    // Record call click before dismissal
    [self incrementNumberTimesContacted:@"call"];
    [self dismiss:sender];
}

- (void)dismissMessage {
    // Record message click before dismissal
    [self incrementNumberTimesContacted:@"message"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)dismissEmail {
    // Record email click before dismissal
    [self incrementNumberTimesContacted:@"email"];
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
