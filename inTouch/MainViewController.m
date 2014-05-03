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

// User interaction
@synthesize contactedView;
@synthesize deletedView;
@synthesize postponedView;
@synthesize busyView;
@synthesize activityIndicator;
@synthesize leftSwipeRecognizer;
@synthesize rightSwipeRecognizer;
@synthesize downSwipeRecognizer;
@synthesize upSwipeRecognizer;
@synthesize tapRecognizer;

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
}

- (void)viewDidAppear:(BOOL)animated {
    // Determine last time we update contact info
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"GlobalData" substitutionVariables:NULL];
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:@"Error getting globals" withPriority:2];
        abort();
    }
    NSManagedObject *globals = [results objectAtIndex:0];
    bool firstRun = [[globals valueForKeyPath:@"firstRun"] boolValue];
    NSDate *today = [NSDate date];
    
    // Update contact info on first run only
    if (firstRun) {
        [DebugLogger log:@"Updating contacts" withPriority:2];
        [self displayBusyViewAndSyncContacts];
        [globals setValue:today forKeyPath:@"lastUpdatedInfo"];
        [globals setValue:today forKey:@"lastUpdatedUrgency"];
        [globals setValue:[NSNumber numberWithBool:NO] forKeyPath:@"firstRun"];
    }
    // Update everyone's urgency once a day (subsequent urgency changes made by user interaction)
    else {
        NSDate *lastUrgencyUpdate = [globals valueForKey:@"lastUpdatedUrgency"];
        NSInteger daysSinceLastUrgnecyUpdate = [self numDaysFrom:lastUrgencyUpdate To:[NSDate date]];
        if (daysSinceLastUrgnecyUpdate != 0) {
            [DebugLogger log:@"Updating urgency for all contacts" withPriority:2];
            [ContactManager updateUrgency];
            [globals setValue:today forKey:@"lastUpdatedUrgency"];
        }
    }
    
    [self getNextContact];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Contact updating

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
        [DebugLogger log:@"No urgent contacts" withPriority:2];
        [self showNoUrgentContacts];
    }
    else {
        // Find the most urgent contact that was not postponed today
        NSUInteger index = 0;
        NSManagedObject *contactMetadata;
        NSDate *lastPostponedDate;
        NSInteger daysSinceLastPostponed;
        do {
            contactMetadata = [results objectAtIndex:index++];
            lastPostponedDate = [contactMetadata valueForKey:@"lastPostponedDate"];
            
            // Break if never postponed
            if (lastPostponedDate == nil) {
                daysSinceLastPostponed = 1; // any nonzero value will do
                break;
            }
            daysSinceLastPostponed = [self numDaysFrom:lastPostponedDate To:[NSDate date]];
        } while (daysSinceLastPostponed == 0 && index < [results count]);
        
        // No urgent contacts that were not postponed today
        if (index == [results count] && daysSinceLastPostponed == 0) {
            [DebugLogger log:@"All contacts postponed today" withPriority:2];
            [self showNoUrgentContacts];
            return;
        }
        
        // Get contact information for the current contact
        NSManagedObject *contact = [contactMetadata valueForKey:@"Contact"];
        [self updateContactInformation:contact];
        
        // Update pertinent UI components
        NSInteger freq = [[contactMetadata valueForKey:@"freq"] integerValue];
        [self updateUI:freq];
        
        [self enableInteraction];
    }
}

// Update information about the current contact
- (void)updateContactInformation:(NSManagedObject*)contact {
    firstName = [contact valueForKey:@"nameFirst"];
    lastName = [contact valueForKey:@"nameLast"];
    abrecordid = [[contact valueForKey:@"abrecordid"] intValue];
    
    // Verify contact ID
    abrecordid = [ContactManager verifyABRecordID:abrecordid forContact:contact];
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef currentContact = ABAddressBookGetPersonWithRecordID(addressBookRef, abrecordid);
    
    // Reset contact info fields
    photoData = NULL;
    emailHome = emailOther = emailWork = phoneHome = phoneMobile = phoneWork = nil;
    
    // Get photo (priority: fb, linkedIn, address book)
    if ([contact valueForKey:@"facebookPhoto"] != NULL) {
        photoData = [contact valueForKey:@"facebookPhoto"];
    } else if ([contact valueForKey:@"linkedinPhoto"] != NULL) {
        photoData = [contact valueForKey:@"linkedinPhoto"];
    } else {
        if (ABPersonHasImageData(currentContact)) {
            photoData = (__bridge_transfer NSData *)ABPersonCopyImageData(currentContact);
            [DebugLogger log:@"Got contact photo" withPriority:1];
        } else {
            [DebugLogger log:@"No contact photo" withPriority:1];
        }
    }
    
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

- (void)updateUI:(NSInteger)freq {
    // Set display name
    NSString *name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    [contactName setText:name];
    
    // Set contact photo
    UIImage *img = [[UIImage alloc] initWithData:photoData];
    [contactPhoto setImage:img];
    
    // Set last contacted label
    if (lastContactedDate) {
        NSInteger daysSinceLastContacted = [self numDaysFrom:lastContactedDate To:[NSDate date]];
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

- (void)showNoUrgentContacts {
    [[self contactName] setText:@"No Urgent Contacts"];
    [self disableInteraction];
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

// Return the number of days from fromDate to toDate
- (NSInteger)numDaysFrom:(NSDate *)fromDate To:(NSDate *)toDate {
    NSDateComponents *diff;
    diff = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:fromDate toDate:toDate options:0];
    NSInteger daysDiff = [diff day];
    return daysDiff;
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
        [self save];
        [self displayPostponedView];
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
        [self displayDeletedView];
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

#pragma mark - Custom Animation

- (void)displayContactedView {
    [self disableInteraction];
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [deletedView setAlpha:1];
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [deletedView setAlpha:0];
        } completion:^(BOOL finished) {
            [self enableInteraction];
        }];
    }];
}

// Display "deleted" icon. Interaction disabled for duration of animation
- (void)displayDeletedView {
    [self disableInteraction];
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [deletedView setAlpha:1];
    }completion:^(BOOL finished) {
       [UIView animateWithDuration:0.3 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
           [deletedView setAlpha:0];
       } completion:^(BOOL finished) {
           [self getNextContact];
           [self enableInteraction];
       }];
    }];
}

// Display "postponed" icon. Interaction disabled for duration of animation
- (void)displayPostponedView {
    [self disableInteraction];
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [postponedView setAlpha:1];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [postponedView setAlpha:0];
        } completion:^(BOOL finished) {
            [self getNextContact];
            [self enableInteraction];
        }];
    }];
}

// Display "syncing contacts" message and sync contacts
- (void)displayBusyViewAndSyncContacts {
    // Show the busy view
    [self disableInteraction];
    [DebugLogger log:@"Showing busy view" withPriority:2];
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [busyView setAlpha:1];
        [activityIndicator startAnimating];
    } completion:^(BOOL finished) {
        [DebugLogger log:@"start updating..." withPriority:2];
        [ContactManager updateInformation];
        [ContactManager updateUrgency];
        [UIView animateWithDuration:0.3 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [busyView setAlpha:0];
        } completion:^(BOOL finished){
            [activityIndicator stopAnimating];
            [self getNextContact];
        }];
    }];
}

// Enable swiping/taping after animation ends
- (void)enableInteraction {
    [leftSwipeRecognizer setEnabled:YES];
    [rightSwipeRecognizer setEnabled:YES];
    [downSwipeRecognizer setEnabled:YES];
    [upSwipeRecognizer setEnabled:YES];
    [frequencySlider setUserInteractionEnabled:YES];
//    [tapRecognizer setEnabled:YES];
}

// Disable swiping/taping during animation
- (void)disableInteraction {
    [DebugLogger log:@"Disabling interaction" withPriority:2];
    [leftSwipeRecognizer setEnabled:NO];
    [rightSwipeRecognizer setEnabled:NO];
    [downSwipeRecognizer setEnabled:NO];
    [upSwipeRecognizer setEnabled:NO];
    [frequencySlider setUserInteractionEnabled:NO];
//    [tapRecognizer setEnabled:NO];
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
