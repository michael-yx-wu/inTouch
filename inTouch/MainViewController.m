//
//  ViewController.m
//  inTouch
//
//  Created by Naicheng Wangyu on 03/01/14.
//  Copyright (c) 2014 Naicheng Wangyu. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>

#import "AppDelegate.h"
#import "ContactManager.h"
#import "MainViewController.h"
#import "ContactViewController.h"

#import "DebugLogger.h"

@interface MainViewController ()
@end

@implementation MainViewController

// Contact display variables
@synthesize contactName;
@synthesize contactPhoto;
@synthesize lastContactedLabel;

@synthesize frequencySlider;
@synthesize viewFrequency;

@synthesize updatingIndicator;

// Contact data variables
@synthesize firstName;
@synthesize lastName;
@synthesize photoData;
@synthesize abrecordid;
@synthesize emailHome;
@synthesize emailOther;
@synthesize emailWork;
@synthesize phoneHome;
@synthesize phoneMobile;
@synthesize phoneWork;
@synthesize lastContactedDate;

- (void)viewDidLoad {
    [super viewDidLoad];
	// Load in background image
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    
    
    // Alertview with basic instructions.
    UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:@"How to Get Started"
                                                      message:@"Swipe left to call, text, or email\n Swipe right to postpone reminder\n Swipe down to remove current contact from future reminders\n"
                                                     delegate:self
                                            cancelButtonTitle:@"Got it"
                                            otherButtonTitles:nil, nil];
    [myAlert show];
    [ContactManager updateInformation];
    [self performSelector:@selector(getNextContact) withObject:nil afterDelay:1.5];
}

// Get most urgent contact upon regaining control
- (void)viewWillAppear:(BOOL)animated {
    [self getNextContact];
}

- (void)fetchNextContactOnEmpty {
    if ([[contactName text] isEqualToString:@"No Urgent Contacts"]) {
        [self getNextContact];
        [DebugLogger log:@"fetching on empty" withPriority:2];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Get the most urgent contact in the database
- (void)getNextContact {
    [DebugLogger log:@"Fetching next contact" withPriority:2];
    // Set up the request
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    NSDictionary *substitionVariables = [[NSDictionary alloc] init];
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"ContactMetadataUrgent" substitutionVariables:substitionVariables];
    
    // Sort by descending urgency
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"urgency" ascending:false];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    // Fetch
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:[NSString stringWithFormat:@"Error getting next contact: %@, %@", error, [error userInfo]] withPriority:2];
        abort();
    }
    
    // Get next urgent contact information if exists
    if ([results count] == 0) {
        [[self contactName] setText:@"No Urgent Contacts"];
    }
    else {
        // Find the most urgent contact that was not postponed today
        NSUInteger index = 0;
        NSManagedObject *contactMetadata;
        NSDate *lastPostponedDate;
        NSDate *today = [NSDate date];
        NSDateComponents *diff;
        NSInteger daysSinceLastPostponed;
        do {
            contactMetadata = [results objectAtIndex:index++];
            lastPostponedDate = [contactMetadata valueForKey:@"lastPostponedDate"];

            // Break if never postponed
            if (lastPostponedDate == nil) {
                break;
            }
            
            diff = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:lastPostponedDate toDate:today options:0];
            daysSinceLastPostponed = [diff day];
        } while (daysSinceLastPostponed == 0 && index < [results count]);
        
        // No urgent contacts that were not postponed today
        if (index == [results count] && daysSinceLastPostponed == 0) {
            [[self contactName] setText:@"No Urgent Contacts"];
            return;
        }
        
        // Get contact information for the current contact
        NSManagedObject *contact = [contactMetadata valueForKey:@"Contact"];
        [self updateContactInformation:contact];
        
        NSInteger freq = [[contactMetadata valueForKey:@"freq"] integerValue];
        
        // Set display name
        NSString *name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        [contactName setText:name];
        
        // Set contact photo
        UIImage *img = [[UIImage alloc] initWithData:photoData];
        [contactPhoto setImage:img];
        
        // Set last contacted label
        if (lastContactedDate) {
            diff = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:lastContactedDate toDate:today options:0];
            NSInteger daysSinceLastContacted = [diff day];
            if (daysSinceLastContacted == 1) {
                [lastContactedLabel setText:@"Last contacted yesterday"];
            }
        } else {
            [lastContactedLabel setText:@""];
        }
        
        // Set frequency slider value and text
        NSString *message;
        if (freq == 1) {
            frequencySlider.value = frequencySlider.minimumValue;
            message = @"Remind me every day";
        }
        else if (freq < 30) {
            frequencySlider.value = freq*10;
            message = [NSString stringWithFormat:@"Remind me every %ld days", (long)freq];
        } else if (freq < 365) {
            frequencySlider.value = (freq/30-1)*60+300;
            message = [NSString stringWithFormat:@"Remind me every %ld months", (long)freq/30];
        } else {
            frequencySlider.value = frequencySlider.maximumValue;
            message = @"Remind me every year";
        }
        [self.viewFrequency setText:message];
    }
}

// Update information about the current contact
- (void)updateContactInformation:(NSManagedObject*)contact {
    firstName = [contact valueForKey:@"nameFirst"];
    lastName = [contact valueForKey:@"nameLast"];
    photoData = [contact valueForKey:@"contactPhoto"];
    abrecordid = [[contact valueForKey:@"abrecordid"] intValue];
    
    // Verify contact ID
    abrecordid = [ContactManager verifyABRecordID:abrecordid forContact:contact];
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef currentContact = ABAddressBookGetPersonWithRecordID(addressBookRef, abrecordid);
    
    // Get home, other, and work emails
    ABMultiValueRef emails = ABRecordCopyValue(currentContact, kABPersonEmailProperty);
    NSString *emailLabel;
    CFStringRef label;
    for (int j = 0; j < ABMultiValueGetCount(emails); j++) {
        // Get label for current email
        label = ABMultiValueCopyLabelAtIndex(emails, j);
        emailLabel = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(label);
        
        if ([emailLabel isEqualToString:@"home"]) {
            emailHome = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, j);
            [DebugLogger log:[NSString stringWithFormat:@"Home Email: %@", emailHome] withPriority:1];
        } else if ([emailLabel isEqualToString:@"other"]) {
            emailOther = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, j);
            [DebugLogger log:[NSString stringWithFormat:@"Other Email: %@", emailOther] withPriority:1];
        } else if ([emailLabel isEqualToString:@"work"]) {
            emailWork = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, j);
            [DebugLogger log:[NSString stringWithFormat:@"Work Email: %@", emailWork] withPriority:1];
        }
    }

    // Get home, mobile, and work phone numbers
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(currentContact, kABPersonPhoneProperty);
    NSString *phoneLabel;
    for (int j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
        // Get label for current phone number
        label = ABMultiValueCopyLabelAtIndex(phoneNumbers, j);
        phoneLabel = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(label);
        
        if ([phoneLabel isEqualToString:@"home"]) {
            phoneHome = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            [DebugLogger log:[NSString stringWithFormat:@"Home Phone: %@", phoneHome] withPriority:1];
        } else if ([phoneLabel isEqualToString:@"mobile"] || [phoneLabel isEqualToString:@"iPhone"]) {
            phoneMobile = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            [DebugLogger log:[NSString stringWithFormat:@"Mobile Phone: %@", phoneMobile] withPriority:1];
        } else if ([phoneLabel isEqualToString:@"work"]) {
            phoneWork = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            [DebugLogger log:[NSString stringWithFormat:@"Work Phone: %@", phoneWork] withPriority:1];
        }
    }

    NSManagedObject *contactMetadata = [contact valueForKey:@"metadata"];
    lastContactedDate = [contactMetadata valueForKey:@"lastContactedDate"];
}

- (void)updateUI {
    
}

// Slider to adjust the frequency of desired contact
- (IBAction)changeFrequency:(id)sender {
    UISlider *freqSlider = (UISlider *)sender;
    
    // Default value or a pre-existing value needs to be determined
    [freqSlider setContinuous:YES];
    [freqSlider setMinimumValue:10];
    [freqSlider setMaximumValue:650];
    
    // Map slider value to remind frequency (in days because of eventual CoreData entry)
    NSInteger frequency;
    NSInteger sliderValue = freqSlider.value;
    if (sliderValue <= 300) {
        frequency = sliderValue/10;
    } else if (sliderValue <= 625) {
        frequency = ((sliderValue-300)/60+1)*30;
    } else {
        frequency = 365;
    }
    
    // Map frequency to user friendly display text
    NSString *message;
    if (frequency == 1) {
        message = @"Remind me every day";
    } else if (frequency <= 30) {
        message = [NSString stringWithFormat:@"Remind me every %ld days", (long)frequency];
    } else if (frequency < 365) {
        NSInteger months = frequency/30;
        message = [NSString stringWithFormat:@"Remind me every %ld months", (long)months];
    } else {
        message = @"Remind me every year";
    }
    [self.viewFrequency setText:message];
}

// Save frequency on touch up on slider
- (IBAction)doneChangingFrequency:(id)sender {
    UISlider *freqSlider = (UISlider *)sender;
    NSInteger frequency;
    NSInteger sliderValue = freqSlider.value;
    if (sliderValue <= 300) {
        frequency = sliderValue/10;
    } else if (sliderValue <= 625) {
        frequency = ((sliderValue-300)/60+1)*30;
    } else {
        frequency = 365;
    }
    
    NSManagedObject *contact = [self fetchContact];
    NSManagedObject *metadata = [contact valueForKey:@"metadata"];
    [metadata setValue:[NSNumber numberWithInteger:frequency] forKey:@"freq"];
    [DebugLogger log:[NSString stringWithFormat:@"New frequency saved: %ld", (long)frequency] withPriority:2];
    [self save];
}

#pragma mark - Swipe/Tap Gestures

- (IBAction)swipeLeftOrTap:(id)sender {
    [DebugLogger log:@"Contact Flip" withPriority:2];
    if (![[contactName text] isEqualToString:@"No Urgent Contacts"]) {
        [self performSegueWithIdentifier:@"contact" sender:sender];
    }
}

- (IBAction)swipeRightOrTap:(id)sender {
    [DebugLogger log:@"Postpone" withPriority:2];
    if (![[contactName text] isEqualToString:@"No Urgent Contacts"]) {
        [DebugLogger log:[NSString stringWithFormat:@"%@ %@ postponed", firstName, lastName] withPriority:2];
        NSManagedObject *contact = [self fetchContact];
        NSManagedObject *metadata = [contact valueForKey:@"metadata"];
        NSDate *today = [NSDate date];
        NSNumber *timesPostponed = [NSNumber numberWithInteger:[[metadata valueForKey:@"numTimesPostponed"] integerValue]+1];
        
        [metadata setValue:today forKey:@"lastPostponedDate"];
        [metadata setValue:timesPostponed forKey:@"numTimesPostponed"];
        [self getNextContact];
    }
}

- (IBAction)swipeDownOrTap:(id)sender {
    [DebugLogger log:@"Delete" withPriority:2];
    if (![[contactName text] isEqualToString:@"No Urgent Contacts"]) {
        NSManagedObject *contact = [self fetchContact];
        NSManagedObject *metadata = [contact valueForKey:@"metadata"];
        NSDate *today = [NSDate date];
        [metadata setValue:[NSNumber numberWithBool:NO] forKey:@"interest"];
        [metadata setValue:today forKey:@"noInterestDate"];
        [self save];
        [self getNextContact];
    }
}

// Fetch Contact entity from coredata based on nanme
- (NSManagedObject *)fetchContact {
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
    if ([results count] != 1) {
        [DebugLogger log:@"Abort! Multiple contacts with same name" withPriority:2];
        abort();
    }
    return [results objectAtIndex:0];
}

#pragma mark - Navigation

// Passing information to ContactViewController before segueing 
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [DebugLogger log:@"Preparing for segue to ContactViewController" withPriority:2];
    
    // Pass contact information to the new view controller.
    if ([[segue identifier] isEqualToString:@"contact"]) {
        ContactViewController *destViewController = [segue destinationViewController];
        [destViewController setFirstName:firstName];
        [destViewController setLastName:lastName];
        [destViewController setPhotoData:[contactPhoto image]];
        [destViewController setEmailHome:emailHome];
        [destViewController setEmailOther:emailOther];
        [destViewController setEmailWork:emailWork];
        [destViewController setPhoneHome:phoneHome];
        [destViewController setPhoneMobile:phoneMobile];
        [destViewController setPhoneWork:phoneWork];
        [destViewController setLastContactedString:[lastContactedLabel text]];
    }
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

- (void)save {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate saveContext];
}

@end
