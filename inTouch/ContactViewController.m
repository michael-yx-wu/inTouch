//
//  ContactViewController.m
//  inTouch
//
//  Created by Michael Wu on 3/24/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

#import "AppDelegate.h"
#import "ContactViewController.h"

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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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
    
    // Update urgency for contact -- this part is overkill (too lazy to rewrite code)
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate updateContactsUrgency];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [DebugLogger log:@"Setting up ContactViewController" withPriority:3];
    
    // Display contact information
    NSString *name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    [contactName setText:name];
    [contactPhoto setImage:photoData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
