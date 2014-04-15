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

@interface ContactViewController ()

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
}

#pragma mark - Button Actions

- (IBAction)messageButton:(id)sender {
    [DebugLogger log:@"Message button press" withPriority:3];
    if (![phoneMobile isEqualToString:@""]) {
//        [self performSegueWithIdentifier:@"message" sender:sender];
        if ([MFMessageComposeViewController canSendText]) {
            NSArray *recipient = @[[NSString stringWithString:phoneMobile]];
            MFMessageComposeViewController *messageViewControler = [[MFMessageComposeViewController alloc] init];
            [messageViewControler setRecipients:recipient];
//            [messageViewControler setDelegate:self];
            
        }
        

//        messageViewControler.messageComposeDelegate = self;
        
        
    } else {
        // Dispay no mobile number
    }
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    [DebugLogger log:@"Preparing for segue to MessageViewController" withPriority:3];
//    // pass some information
//    
//}

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
//    [self updateUrgency];
    [UrgencyCalculator updateUrgencyFirstName:firstName lastName:lastName];
}

-(void)updateUrgency {
    NSArray *results = [self fetchContact];
    if ([results count] != 1) {
        [DebugLogger log:[NSString stringWithFormat:@"Aborting! Multiple contacts with same name: %@ %@", firstName, lastName] withPriority:3];
        abort();
    }
    NSManagedObject *contact = [results objectAtIndex:0];
    NSManagedObject *metadata = [contact valueForKey:@"metadata"];
    
    NSDate *lastContactedDate = [metadata valueForKey:@"lastContactedDate"];
    NSDate *currentDate = [NSDate date];
    NSDateComponents *diff;
    double daysSinceLastContact;
    double freq = [[metadata valueForKey:@"freq"] doubleValue];
    
    // Update urgency based on frequencies and last date contacted
    // For now, urg = (currentdate - lastdate)/freq or 0 if
    // the expression < 1
    NSNumber *urgency;
    
    // If never contacted, default urgency is 1
    if (lastContactedDate == nil) {
        urgency = [NSNumber numberWithDouble:1];
    }
    // Calculate urg using formula above
    else {
        diff = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:lastContactedDate toDate:currentDate options:0];
        daysSinceLastContact = [diff day];
        urgency = [NSNumber numberWithDouble:daysSinceLastContact/freq];
        if ([urgency doubleValue] < 1) {
            urgency = [NSNumber numberWithDouble:0];
        }
    }
    
    // Save the new urgency value
    [metadata setValue:urgency forKey:@"urgency"];
    [DebugLogger log:[NSString stringWithFormat:@"New urgency for %@ %@: %f", firstName, lastName, [urgency doubleValue]] withPriority:1];
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

- (IBAction)dismissMessage:(id)sender {
    // Record message click before dismissal
    [self incrementNumberTimesContacted:@"message"];
    [self dismiss:sender];
}

- (IBAction)dismissEmail:(id)sender {
    // Record email click before dismissal
    [self incrementNumberTimesContacted:@"email"];
    [self dismiss:sender];
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
