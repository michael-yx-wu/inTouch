#import <AddressBookUI/AddressBookUI.h>

#import "AppDelegate.h"
#import "Contact.h"
#import "ContactMetadata.h"
#import "ContactManager.h"
#import "GlobalData.h"
#import "MainViewController.h"
#import "ContactViewController.h"

#import "DebugConstants.h"
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
@synthesize syncingView;
@synthesize syncingActivityIndicator;
@synthesize updatingUrgencyView;
@synthesize updatingUrgencyActivityIndicator;
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

// Keep 5 contacts in the queue, ordered by "most urgent" first
@synthesize contactQueue;
@synthesize facebookFriends;

// Debug priority
- (void)viewDidLoad {
    [super viewDidLoad];
	// Load in background image
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    
    // Make contact photo round
    [[contactPhoto layer] setCornerRadius:contactPhoto.frame.size.width/2];
    [[contactPhoto layer] setMasksToBounds:YES];
    
    // Initialize contact queue
    contactQueue = [[NSMutableArray alloc] init];
    
    // Get list of facebook friends
    [FBRequestConnection startWithGraphPath:@"/me/taggable_friends?fields=name,picture.width(500),picture.height(500)"                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            [DebugLogger log:[NSString stringWithFormat:@"request error: %@", [error userInfo]] withPriority:contactManagerPriority];
            return;
        }
        
        // Process facebook json object
        NSArray *taggableFriends = [result objectForKey:@"data"];
        for (NSDictionary *friend in taggableFriends) {
            NSString *name = [friend valueForKey:@"name"];
            NSArray *picture = [friend valueForKey:@"picture"];
            NSArray *pictureData = [picture valueForKey:@"data"];
            NSString *url = [NSString stringWithString:[pictureData valueForKey:@"url"]];
            [facebookFriends setValue:url forKey:name];
        }
    }];
    
    // Add notification observer to listen for a list of facebook friends
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFacebookFriends:) name:@"facebookFriends" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearQueue:) name:@"clearQueue" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    // Determine last time we update contact info
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"GlobalData" substitutionVariables:NULL];
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:@"Error getting globals" withPriority:mainViewControllerPriority];
        abort();
    }
    GlobalData *globalData = [results objectAtIndex:0];
    
    // Update contact info on first run only
    NSDate *today = [NSDate date];
    bool firstRun = [[globalData firstRun] boolValue];
    if (firstRun) {
        [DebugLogger log:@"First run today - syncing contacts" withPriority:mainViewControllerPriority];
        [self requestContactsAccessAndSync];
        [globalData setLastUpdatedInfo:today];
        [globalData setLastUpdatedUrgency:today];
        [globalData setFirstRun:[NSNumber numberWithBool:NO]];
    }
    // Update everyone's urgency once a day (subsequent urgency changes made by user interaction)
    else {
        NSDate *today = [NSDate date];
        NSDate *lastUrgencyUpdate = [globalData lastUpdatedUrgency];
        NSInteger daysSinceLastUrgencyUpdate = 1;
        if (lastUrgencyUpdate != nil) {
            daysSinceLastUrgencyUpdate = [self numDaysFrom:lastUrgencyUpdate To:today];
        }
        if (daysSinceLastUrgencyUpdate != 0) {
            [DebugLogger log:@"Updating urgency for all contacts" withPriority:mainViewControllerPriority];
            [ContactManager updateUrgency];
            [globalData setLastUpdatedUrgency:today];
        }
    }
    
    [self updateQueue];
    [self getNextContactFromQueue];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Contact updating

- (void)mergeChanges:(NSNotification *)notification {
    NSLog(@"got merge notification");
    [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
    
}

- (void)clearQueue:(NSNotification *)notfication {
    [contactQueue removeAllObjects];
}

- (void)updateFacebookFriends:(NSNotification *)notification {
    NSLog(@"got new friend list");
    facebookFriends = [[notification userInfo] valueForKey:@"data"];
    
    // Try again to download facebook photos for all contacts that don't have facebook photos in the queue
    for (Contact *contact in contactQueue) {
        if (![contact facebookPhoto]) {
            [self downloadFbPhotoForContact:contact];
        }
    }
}

// Asynchronously attempts to download a facebook photo for the contact
- (void)downloadFbPhotoForContact:(Contact *)contact {
    NSManagedObjectID *contactID = [contact objectID];
    MainViewController *thisController = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            [moc setPersistentStoreCoordinator:[appDelegate persistentStoreCoordinator]];
            Contact *someContact = (Contact *)[moc objectWithID:contactID];
            
            [[NSNotificationCenter defaultCenter] addObserver:thisController selector:@selector(mergeChanges:) name:NSManagedObjectContextDidSaveNotification object:moc];
            
            NSString *fullName = [NSString stringWithFormat:@"%@ %@", [someContact nameFirst], [someContact nameLast]];
            NSString *url = [facebookFriends valueForKey:fullName];
            NSLog(@"%@", url);
            if (url) {
                NSLog(@"Downloading photo for contact: %@", fullName);
                NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
                [someContact setFacebookPhoto:imageData];
                NSError *error;
                if ([moc hasChanges]) {
                    [moc save:&error];
                }
            }

            // If we happened to download the photo for the current contact, reload photo
            if ([[someContact nameFirst] isEqualToString:firstName] &&
                [[someContact nameLast] isEqualToString:lastName]) {
                [thisController updateContactInformationAfterFetch:[someContact objectID]];
            }
            
            [[NSNotificationCenter defaultCenter] removeObserver:thisController name:NSManagedObjectContextDidSaveNotification object:moc];
        }
        @catch (NSException *exception) {
            NSLog(@"error: thread probably terminated mid execution");
        }
    });
}

- (void)updateContactInformationAfterFetch:(NSManagedObjectID *)objectID {
    Contact *contact = (Contact *)[[self managedObjectContext] objectWithID:objectID];
    [self updateContactInformation:contact];
}

// Attempt to get the next contact from the contactQueue
- (void)getNextContactFromQueue {
    if ([contactQueue count] != 0) {
        Contact *contact = (Contact *)[contactQueue objectAtIndex:0];
        ContactMetadata *metadata = (ContactMetadata *)[contact metadata];
        
        [contactQueue removeObjectAtIndex:0];
        [self updateContactInformation:contact];
        
        // Update pertinent UI components
        NSInteger freq = [[metadata freq] integerValue];
        [self updateUI:freq];
        [self enableInteraction];
    } else {
        [self showNoUrgentContacts];
    }
}

- (void)updateQueue {
    [DebugLogger log:@"Updating queue"
        withPriority:mainViewControllerPriority];
    
    // Set up the request
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    NSDictionary *substitionVariables = [[NSDictionary alloc] init];
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"ContactMetadataUrgent"
                                                substitutionVariables:substitionVariables];
    
    // Sort by descending urgency
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"urgency" ascending:false];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    // Execute request
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:[NSString stringWithFormat:@"Error getting next contact: %@, %@", error, [error userInfo]] withPriority:mainViewControllerPriority];
        abort();
    }
    
    // Look for contacts to add to queue while length < 5 or
    // until we exhaust the list of urgent contacts
    NSUInteger index = 0;
    ContactMetadata *metadata;
    NSDate *lastPostponedDate;
    while ([contactQueue count] < 5 && index < [results count]) {
        metadata = [results objectAtIndex:index++];
        lastPostponedDate = [metadata lastPostponedDate];
        Contact *contact = (Contact *)[metadata contact];

        // Never postponed, add to queue if not already in queue
        // Otherwise, add to queue if not postponed today and not already in queue
        // Note: If nil, the second statement in the if will not evaluate,
        // so this is safe
        if (lastPostponedDate == nil || [self numDaysFrom:lastPostponedDate To:[NSDate date]]) {
            if (![self queueContainsContact:contact]) {
                [self downloadFbPhotoForContact:contact];
                // Add contact to queue
                [contactQueue addObject:contact];
            }
        }
        
    }
}

// Helper method that returns true if our contactQueue has an object containing the contents of the specified contact
- (BOOL)queueContainsContact:(Contact *)contact {
    for (Contact *queuedContact in contactQueue) {
        if ([[[queuedContact objectID] URIRepresentation] isEqual:[[contact objectID] URIRepresentation]]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Deprecated contact fetching methods

// Update information about the current contact
- (void)updateContactInformation:(Contact *)contact {
    // Get key contact info
    firstName = [contact nameFirst];
    lastName = [contact nameLast];
    abrecordid = [[contact abrecordid] intValue];
    
    // Verify contact ID
    abrecordid = [ContactManager verifyABRecordID:abrecordid forContact:contact];
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef currentContact = ABAddressBookGetPersonWithRecordID(addressBookRef, abrecordid);
    
    // Reset contact info fields
    photoData = NULL;
    emailHome = emailOther = emailWork = phoneHome = phoneMobile = phoneWork = nil;
    
    // Get photo (priority: fb, twitter, address book)
    NSData *facebookPhoto = [contact facebookPhoto];
    NSData *linkedinPhoto = [contact linkedinPhoto];
    if (facebookPhoto != NULL) {
        photoData = facebookPhoto;
    } else if (linkedinPhoto != NULL) {
        photoData = linkedinPhoto;
    } else {
        if (ABPersonHasImageData(currentContact)) {
            photoData = (__bridge_transfer NSData *)ABPersonCopyImageData(currentContact);
            [DebugLogger log:@"Got contact photo" withPriority:mainViewControllerPriority];
        } else {
            UIImage *img = [UIImage imageNamed:@"default_pf_v2.png"];
            photoData = UIImagePNGRepresentation(img);
            [DebugLogger log:@"No contact photo" withPriority:mainViewControllerPriority];
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
            [DebugLogger log:[NSString stringWithFormat:@"Home Email: %@", emailHome] withPriority:mainViewControllerPriority];
        } else if ([emailLabel isEqualToString:@"other"]) {
            emailOther = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, j);
            [DebugLogger log:[NSString stringWithFormat:@"Other Email: %@", emailOther] withPriority:mainViewControllerPriority];
        } else if ([emailLabel isEqualToString:@"work"]) {
            emailWork = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, j);
            [DebugLogger log:[NSString stringWithFormat:@"Work Email: %@", emailWork] withPriority:mainViewControllerPriority];
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
            [DebugLogger log:[NSString stringWithFormat:@"Home Phone: %@", phoneHome] withPriority:mainViewControllerPriority];
        } else if ([phoneLabel isEqualToString:@"mobile"] || [phoneLabel isEqualToString:@"iPhone"]) {
            phoneMobile = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            [DebugLogger log:[NSString stringWithFormat:@"Mobile Phone: %@", phoneMobile] withPriority:mainViewControllerPriority];
        } else if ([phoneLabel isEqualToString:@"work"]) {
            phoneWork = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            [DebugLogger log:[NSString stringWithFormat:@"Work Phone: %@", phoneWork] withPriority:mainViewControllerPriority];
        }
    }
    
    ContactMetadata *contactMetadata = (ContactMetadata *)[contact metadata];
    lastContactedDate = [contactMetadata lastContactedDate];
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
    
    // Clear the contact photo
    [contactPhoto setImage:[[UIImage alloc] init]];
    
    
    // not done -- also need to hide/unhide other elements
    
    // Prevent contact buttons from doing anything
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
    int frequency;
    double sliderValue = [freqSlider value];
    if (sliderValue <= 300) {
        frequency = sliderValue/10;
    } else if (sliderValue <= 625) {
        frequency = ((sliderValue-300)/60+1)*30;
    } else {
        frequency = 365;
    }
    
    Contact *contact = [self fetchContact];
    ContactMetadata *metadata = (ContactMetadata *)[contact metadata];
    [metadata setFreq:[NSNumber numberWithInt:frequency]];
    [DebugLogger log:[NSString stringWithFormat:@"New frequency saved: %d", frequency] withPriority:mainViewControllerPriority];
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

// Show the contact options for current contact
- (IBAction)swipeLeftOrTap:(id)sender {
    [DebugLogger log:@"Contact Flip" withPriority:mainViewControllerPriority];
    if (![[contactName text] isEqualToString:@"No Urgent Contacts"]) {
        [self performSegueWithIdentifier:@"contact" sender:sender];
    }
}

// Postpone the current contact
- (IBAction)swipeRightOrTap:(id)sender {
    [DebugLogger log:@"Postpone" withPriority:2];
    if (![[contactName text] isEqualToString:@"No Urgent Contacts"]) {
        [DebugLogger log:[NSString stringWithFormat:@"%@ %@ postponed", firstName, lastName] withPriority:mainViewControllerPriority];
        Contact *contact = [self fetchContact];
        ContactMetadata *metadata = (ContactMetadata *)[contact metadata];
        NSDate *today = [NSDate date];
        NSNumber *timesPostponed = [NSNumber numberWithInteger:[[metadata numTimesPostponed] integerValue]+1];
        [metadata setLastPostponedDate:today];
        [metadata setNumTimesPostponed:timesPostponed];
        [self save];
        [self displayPostponedView];
    }
}

// Delete the current contact
- (IBAction)swipeDownOrTap:(id)sender {
    [DebugLogger log:@"Delete" withPriority:mainViewControllerPriority];
    if (![[contactName text] isEqualToString:@"No Urgent Contacts"]) {
        Contact *contact = [self fetchContact];
        ContactMetadata *metadata = (ContactMetadata *)[contact metadata];
        NSDate *today = [NSDate date];
        [metadata setNoInterestDate:today];
        [metadata setInterest:[NSNumber numberWithBool:NO]];
        [self save];
        [self displayDeletedView];
    }
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
            [self updateQueue];
            [self getNextContactFromQueue];
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
            [self updateQueue];
            [self getNextContactFromQueue];
            [self enableInteraction];
        }];
    }];
}

// Display "syncing contacts" message and sync contacts
- (void)displaySyncingViewAndSyncContacts {
    // Show the busy view
    [self disableInteraction];
    [DebugLogger log:@"Showing syncing view" withPriority:mainViewControllerPriority];
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [syncingView setAlpha:1];
        [syncingActivityIndicator startAnimating];
    } completion:^(BOOL finished) {
        [DebugLogger log:@"start updating..." withPriority:mainViewControllerPriority];
        [ContactManager updateInformation];
        [ContactManager updateUrgency];
        [self save];
        [UIView animateWithDuration:0.3 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [syncingView setAlpha:0];
        } completion:^(BOOL finished){
            [syncingActivityIndicator stopAnimating];
            [self updateQueue];
            [self getNextContactFromQueue];
        }];
    }];
}

// Display "updating urgencies" message and update urgencies for all
- (void)displayUpdatingUrgenciesViewAndUpdateUrgencies {
    // Show the updating view
    [self disableInteraction];
    [DebugLogger log:@"Showing busy view" withPriority:mainViewControllerPriority];
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [updatingUrgencyView setAlpha:1];
        [updatingUrgencyActivityIndicator startAnimating];
    } completion:^(BOOL finished) {
        [DebugLogger log:@"start updating urgencies" withPriority:mainViewControllerPriority];
        [ContactManager updateUrgency];
        [UIView animateWithDuration:0.3 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [updatingUrgencyView setAlpha:0];
        } completion:^(BOOL finished) {
            [updatingUrgencyActivityIndicator stopAnimating];
            [self updateQueue];
            [self getNextContactFromQueue];
        }];
    }];
}


// Enable swiping/taping after animation ends
- (void)enableInteraction {
    [DebugLogger log:@"Enabling interaction" withPriority:mainViewControllerPriority];
    [leftSwipeRecognizer setEnabled:YES];
    [rightSwipeRecognizer setEnabled:YES];
    [downSwipeRecognizer setEnabled:YES];
    [upSwipeRecognizer setEnabled:YES];
    [frequencySlider setUserInteractionEnabled:YES];
}

// Disable swiping/taping during animation
- (void)disableInteraction {
    [DebugLogger log:@"Disabling interaction" withPriority:mainViewControllerPriority];
    [leftSwipeRecognizer setEnabled:NO];
    [rightSwipeRecognizer setEnabled:NO];
    [downSwipeRecognizer setEnabled:NO];
    [upSwipeRecognizer setEnabled:NO];
    [frequencySlider setUserInteractionEnabled:NO];
}

#pragma mark - Navigation

// Passing information to ContactViewController before segueing
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [DebugLogger log:@"Preparing for segue to ContactViewController" withPriority:mainViewControllerPriority];
    
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

#pragma mark - Core Data Methods

- (NSManagedObjectContext *)managedObjectContext {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate managedObjectContext];
}

- (NSManagedObjectModel *)managedObjectModel {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate managedObjectModel];
}

// Request contacts access and sync if authorized
- (void)requestContactsAccessAndSync {
    // Request authorization to Address Book
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error){
            if (granted) {
                [self displaySyncingViewAndSyncContacts];
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        [self displaySyncingViewAndSyncContacts];
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) {
        UIAlertView *deniedMessage = [[UIAlertView alloc] initWithTitle:@"Access to Contacts" message:@"Go to 'Settings > Privacy > Contacts' to change." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [deniedMessage show];
    }
}

// Fetch Contact entity from coredata based on nanme
- (Contact *)fetchContact {
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
                          error, [error userInfo]] withPriority:mainViewControllerPriority];
        abort();
    }
    if ([results count] != 1) {
        [DebugLogger log:@"Abort! Multiple contacts with same name" withPriority:mainViewControllerPriority];
        abort();
    }
    return [results objectAtIndex:0];
}

// Save current context
- (void)save {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate saveContext];
}

@end
