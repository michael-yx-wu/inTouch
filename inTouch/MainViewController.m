#import <AddressBookUI/AddressBookUI.h>

#import "AppDelegate.h"
#import "Contact.h"
#import "ContactMetadata.h"
#import "ContactManager.h"
#import "FacebookManager.h"
#import "GlobalData.h"
#import "NotificationStrings.h"

#import "MainViewController.h"
#import "ContactViewController.h"
#import "LoginViewController.h"
#import "PickerViewController.h"
#import "TutorialViewController.h"

#define RESOLUTION_THRESHOLD 0

@interface MainViewController () {
    NSMutableArray *photoQueue;
    NSMutableArray *currentQueue;
    NSMutableDictionary *fbDownloadStatus;
    Contact *currentContact;
}
@end

@implementation MainViewController

// Contact display variables
@synthesize contactQueueView;
@synthesize contactCard;
@synthesize contactName;
@synthesize contactPhotoFront;
@synthesize contactPhotoMiddle;
@synthesize contactPhotoBottom;
@synthesize contactPhotoAnchor;

// User interaction
@synthesize contactActionButtonsView;
@synthesize deletedView;
@synthesize postponedView;
@synthesize syncingView;
@synthesize syncingActivityIndicator;

// Keep 5 contacts in the queue, ordered by "most urgent" first
@synthesize contactAppearedQueue;
@synthesize contactNeverAppearedQueue;
@synthesize facebookFriends;
@synthesize switchQueueButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Load in background image
    [[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]]];
    
    // Add the references to the contact queue
    photoQueue = [[NSMutableArray alloc] initWithCapacity:4];
    [photoQueue addObject:contactPhotoFront];
    [photoQueue addObject:contactPhotoMiddle];
    [photoQueue addObject:contactPhotoBottom];
    [photoQueue addObject:contactPhotoAnchor];
    
    // Add contact card and queues as subviews
    [[self view] addSubview:contactCard];
    [[self view] addSubview:contactQueueView];
    [contactCard setDelegate:self];
    [contactQueueView setDelegate:self];
    
    // Initialize the queues
    contactAppearedQueue = [[NSMutableArray alloc] initWithCapacity:5];
    contactNeverAppearedQueue = [[NSMutableArray alloc] initWithCapacity:5];
    
    // Initialize the contact queue with at most 5 urgent contacts - load appeared queue on default
    currentQueue = contactAppearedQueue;
    [self updateQueue];
    [self printQueue];
    currentQueue = contactNeverAppearedQueue;
    [self updateQueue];
    [self printQueue];
    currentQueue = contactAppearedQueue;
    [self getNextContactFromQueue];
    
    // Switch to new contact queue if no reminders have been set
    if (!currentContact) {
        currentQueue = contactNeverAppearedQueue;
        [switchQueueButton setImage:[UIImage imageNamed:@"eye_queue_closed.png"] forState:UIControlStateNormal];
        [self getNextContactFromQueue];
    }
    
    // Switch back to reminders queue if no new contacts
    if (!currentContact) {
        currentQueue = contactAppearedQueue;
        [switchQueueButton setImage:[UIImage imageNamed:@"eye_queue_open.png"] forState:UIControlStateNormal];
    }
    
    [self updatePhotosDisplayedInQueue];
    
    // Track current facebook downloads
    fbDownloadStatus = [[NSMutableDictionary alloc] init];
    
    // Listen for notification to replace facebook friend list with new list
    // Notification from ContactManager
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFacebookFriends:)
                                                 name:gotFacebookFriendsNotification
                                               object:nil];
    
    // Listen for notification to redraw profile photos when downloads finish. Photos can take several seconds to load.
    // Notification from self (background process)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePhotosDisplayedInQueue)
                                                 name:photoDownloadedNotification
                                               object:nil];
    
    // Listen for notification to show picker view and select a remind date
    // Notification from ContactViewController
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactWasContacted:)
                                                 name:contactedNotification
                                               object:nil];
    
    // Listen for notification to set the remind date and slide up
    // Notification from PickerViewController
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pickerViewDone:)
                                                 name:pickerViewDoneNotification
                                               object:nil];
    
    // Listen for notification to dismiss the picker view controller and do nothing
    // Notification from PickerViewController
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pickerViewCancel:)
                                                 name:pickerViewCancelNotification
                                               object:nil];
    
    // Listen for notifications to update the UI for the current queue after a queue switch
    // Notifications from ContactQueueView
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUIForCurrentQueue:)
                                                 name:queueSwitchingDoneNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookLogin:)
                                                 name:registeredForNotifications
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Save the original centers after main view has loaded -- method is screen width dependent
    [contactCard setImageCentersAndMasks];
    [contactQueueView setImageCenter];
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [contactQueueView setAlpha:1];
        [self updateUIForCurrentQueue:nil];
    } completion:^(BOOL finished) {
        // Automatically sync contact info on first run only
        GlobalData *globalData = [self getGlobalDataEntity];
        bool firstRun = [[globalData firstRun] boolValue];
        if (firstRun) {
            [globalData setLastUpdatedInfo:[NSDate date]];
            [globalData setFirstRun:[NSNumber numberWithBool:NO]];
            
            // TutorialViewController will sync contacts on dismissal
            [self performSegueWithIdentifier:@"tutorial" sender:self];            
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Remove contacts that are marked as "not interested"
    int i;
    for (i = 0; i < [contactAppearedQueue count]; i++) {
        ContactMetadata *metadata = (ContactMetadata *)[(Contact *)[contactAppearedQueue objectAtIndex:i] metadata];
        if (![[metadata interest] boolValue]) {
            [contactAppearedQueue removeObjectAtIndex:i];
        }
    }
    for (i = 0; i < [contactNeverAppearedQueue count]; i++) {
        ContactMetadata *metadata = (ContactMetadata *)[(Contact *)[contactNeverAppearedQueue objectAtIndex:i] metadata];
        if (![[metadata interest] boolValue]) {
            [contactNeverAppearedQueue removeObjectAtIndex:i];
        }
    }
    [self getNextContactFromQueue];
    [self updateQueue];
    [self updatePhotosDisplayedInQueue];
    [self printQueue];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Contact updating

- (void)getNextContactFromQueue {
    if ([currentQueue count]) {
        currentContact = [currentQueue objectAtIndex:0];
    } else {
        [DebugLogger log:@"No contacts left in queue" withPriority:mainViewControllerPriority];
        currentContact = nil;
    }
}

// Fill up the current queue with at most 5 contacts, sorted by descending urgency
- (void)updateQueue {
    [DebugLogger log:@"Updating queue" withPriority:mainViewControllerPriority];
    // Execute fetch request for contactAppearedQueue or contactNeverAppearedQueue depending on the currentQueue
    NSManagedObjectModel *model = [self managedObjectModel];
    NSFetchRequest *request;
    if (currentQueue == contactAppearedQueue) {
        NSDictionary *substitionVariables = [NSDictionary dictionaryWithObjectsAndKeys:[NSDate date], @"DATE", nil];
        request = [model fetchRequestFromTemplateWithName:@"ContactMetadataUrgent"
                                    substitutionVariables:substitionVariables];
        
        // Set the sort descriptor to sort by descending urgency and execute
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"remindOnDate" ascending:false];
        NSArray *sortDescriptors = @[sortDescriptor];
        [request setSortDescriptors:sortDescriptors];
    }
    else {
        // Get all contacts that have never appeared
        request = [model fetchRequestFromTemplateWithName:@"ContactMetadataNeverAppeared"
                                    substitutionVariables:[[NSDictionary alloc] init]];
    }
    NSArray *results = [self executeFetchRequest:request];
    
    // Get contacts to add to currentQueue while length < 5 or until we exhuast the list of urgent contacts
    ContactMetadata *metadata;
    NSUInteger index = 0;
    while ([currentQueue count] < 5 && index < [results count]) {
        metadata = [results objectAtIndex:index++];
        Contact *contact = (Contact *)[metadata contact];
        
        // Add contact to queue if not already in queue
        if (![self queue:currentQueue ContainsContact:contact]) {
            [self downloadFbPhotoForContact:contact];
            // Add contact to queue
            [currentQueue addObject:contact];
        }
    }
}

// Helper method that executes the given fetch request and returns the results
- (NSArray *)executeFetchRequest:(NSFetchRequest *)request {
    NSManagedObjectContext *moc = [self managedObjectContext];
    // Execute request
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        NSString *errorString = [NSString stringWithFormat:@"Error getting next contact: %@, %@", error,
                                 [error userInfo]];
        [DebugLogger log:errorString withPriority:mainViewControllerPriority];
        abort();
    }
    return results;
}

// Show the PickerViewController. Hide the cancel button
- (void)contactWasContacted:(NSNotification *)notification {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PickerViewController *pvc = [storyboard instantiateViewControllerWithIdentifier:@"picker"];
    [pvc setShouldHideCancelButton:YES];
    [pvc setPostponingContact:NO];
    [pvc setDisplayedInMainView:YES];
    [pvc setContact:currentContact];
    [pvc setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [self presentViewController:pvc animated:YES completion:nil];
}

// This method is only called when swiping to postpone a contact
- (void)showPickerView {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PickerViewController *pvc = [storyboard instantiateViewControllerWithIdentifier:@"picker"];
    [pvc setShouldHideCancelButton:NO];
    [pvc setPostponingContact:YES];
    [pvc setPostponingContactFromButton:NO];
    [pvc setDisplayedInMainView:YES];
    [pvc setContact:currentContact];
    [pvc setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [self presentViewController:pvc animated:YES completion:nil];
}

// Save relevant metadata and slide the contact up
- (void)pickerViewDone:(NSNotification *)notification {
    [self dismissViewControllerAnimated:YES completion:^{
        NSDictionary *dict = [notification userInfo];
        NSNumber *daysToPostpone = [dict valueForKey:@"days"];
        BOOL postponingContact = [[dict valueForKey:@"postponingContact"] boolValue];
        BOOL postponingContactFromButton = [[dict valueForKey:@"postponingContactFromButton"] boolValue];
        
        // Remember days to postpone as user preference
        ContactMetadata *metadata = (ContactMetadata *)[currentContact metadata];
        [metadata setDaysBetweenReminder:daysToPostpone];
        
        // We finished contacting a contact
        if (!postponingContact) {
            [contactCard slideContactCardUp:[daysToPostpone integerValue]];
        }
        // We are postponing from a button
        else if (postponingContactFromButton) {
            [contactCard rightActionFromButton:[daysToPostpone integerValue]];
        }
        // We are postponing from a swipe -- this is a little hairy
        else {
            // Contact is already off the screen. We just need to update photos and return to original positions
            [self dismissContactAndSetReminder:[daysToPostpone unsignedIntegerValue]];
            [contactCard returnToOriginalPositions];
            [contactCard showNameLabel];
        }
    }];
}

// Dismiss the picker view and move cards back to original positions if necessary
- (void)pickerViewCancel:(NSNotification *)notification {
    [self dismissViewControllerAnimated:YES completion:^{
        [UIView animateWithDuration:0.3 animations:^{
            [contactCard returnToOriginalPositions];
        } completion:^(BOOL finished) {
            [contactCard showNameLabel];
        }];
    }];
}

// 1. Remove the contact from the current queue and the download status dictionary
// 2. Update the current queue
// 3. Repoint the current contact
// 4. Redraw photos
- (void)dismissContact {
    [currentQueue removeObjectAtIndex:0];
    @synchronized(fbDownloadStatus) {
        [fbDownloadStatus removeObjectForKey:[currentContact objectID]];
    }
    [self getNextContactFromQueue];
    [self updateQueue];
    [self updatePhotosDisplayedInQueue];
    [self printQueue];
}

// 1. Set the remindOnDate metadata property and remind in some number of days
// 2. Dismiss contact called when done
- (void)dismissContactAndSetReminder:(NSUInteger)days {
    [self printQueue];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *todaysComponents = [calendar components:(NSCalendarUnitYear|
                                                               NSCalendarUnitMonth|
                                                               NSCalendarUnitDay|
                                                               NSCalendarUnitTimeZone|
                                                               NSCalendarUnitCalendar)
                                                     fromDate:[NSDate date]];
    NSDate *today = [todaysComponents date];
    NSDateComponents *futureComponents = [[NSDateComponents alloc] init];
    [futureComponents setDay:days];
    NSDate *remindDate = [calendar dateByAddingComponents:futureComponents toDate:today options:0];
    ContactMetadata *contactMetadata = (ContactMetadata *)[currentContact metadata];
    [contactMetadata setNumTimesAppeared:[NSNumber numberWithInt:([[contactMetadata numTimesAppeared] intValue] + 1)]];
    [contactMetadata setRemindOnDate:remindDate];
    [self save];
    [self dismissContact];
}

// Helper method that returns true if the specified queue contains a copy of the contact
- (BOOL)queue:(NSMutableArray *)queue ContainsContact:(Contact *)contact {
    for (Contact *queuedContact in queue) {
        if([[[queuedContact objectID] URIRepresentation] isEqual:[[contact objectID] URIRepresentation]]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Facebook methods

// Request facebook login
- (void)facebookLogin:(NSNotification *)notification {
    UIAlertController *notNow = [UIAlertController alertControllerWithTitle:@""
                                                                    message:@"Facebook preferences can be changed in the settings menu"
                                                             preferredStyle:UIAlertControllerStyleAlert];
    [notNow addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
    UIAlertController *facebookLoginRequest = [UIAlertController alertControllerWithTitle:@"Connect to Facebook"
                                                                                  message:@"Logging in will allow us to use Facebook profile photos for your contacts when available. We will never post to Facebook."
                                                                           preferredStyle:UIAlertControllerStyleAlert];
    [facebookLoginRequest addAction:[UIAlertAction actionWithTitle:@"Connect"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               [FacebookManager login];
                                                           }]];
    [facebookLoginRequest addAction:[UIAlertAction actionWithTitle:@"Not now"
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction *action) {
                                                               [self presentViewController:notNow
                                                                                  animated:YES
                                                                                completion:nil];
                                                           }]];
    [self presentViewController:facebookLoginRequest animated:YES completion:nil];
}

- (void)updateFacebookFriends:(NSNotification *)notification {
    [DebugLogger log:@"Got new facebook friend list" withPriority:mainViewControllerPriority];
    facebookFriends = [[notification userInfo] valueForKey:@"data"];
    [self reloadAllFacebookPhotos];
    [self updatePhotosDisplayedInQueue];
}

- (void)reloadAllFacebookPhotos {
    for (Contact *contact in contactAppearedQueue) {
        [self downloadFbPhotoForContact:contact];
    }
    for (Contact *contact in contactNeverAppearedQueue) {
        [self downloadFbPhotoForContact:contact];
    }
}

// Asynchronously attempts to download a facebook photo for the contact
- (void)downloadFbPhotoForContact:(Contact *)contact {
    NSManagedObjectID *contactID = [contact objectID];
    MainViewController *thisController = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            // Use a reference to app delegate's moc
            NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            [moc setPersistentStoreCoordinator:[appDelegate persistentStoreCoordinator]];
            Contact *someContact = (Contact *)[moc objectWithID:contactID];
            
            NSString *fullName = [NSString stringWithFormat:@"%@ %@", [someContact nameFirst], [someContact nameLast]];
            NSString *url = [facebookFriends objectForKey:fullName];
            
            // Got a profile picture url for friend -- begin downloading
            if (url) {
                @synchronized(fbDownloadStatus) {
                    // Abort download for contact if there is already a download in progress
                    NSNumber *downloadStatus = [fbDownloadStatus objectForKeyedSubscript:[contact objectID]];
                    if ([downloadStatus boolValue]) {
                        [DebugLogger log:[NSString stringWithFormat:@"Already downloading photo for %@", fullName]
                            withPriority:mainViewControllerPriority];
                        return;
                    }
                    // Prevent other threads beginning a download while a download is in progress
                    else {
                        [fbDownloadStatus setObject:[NSNumber numberWithBool:YES] forKey:[contact objectID]];
                    }
                }
                
                // Dynamically add an observer to this controller to listen for context merge requests from other threads
                [[NSNotificationCenter defaultCenter] addObserver:thisController
                                                         selector:@selector(mergeChanges:)
                                                             name:NSManagedObjectContextDidSaveNotification
                                                           object:moc];
                
                [DebugLogger log:[NSString stringWithFormat:@"Downloading photo for %@", fullName]
                    withPriority:mainViewControllerPriority];
                NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
                [someContact setFacebookPhoto:imageData];
                [DebugLogger log:[NSString stringWithFormat:@"Got photo for %@", fullName]
                    withPriority:mainViewControllerPriority];

                NSError *error;
                if ([moc hasChanges]) {
                    @synchronized(fbDownloadStatus) {
                        [moc save:&error]; // this will cause main thread to merge changes
                        
                        // Allow other threads to begin downloads after our save complete
                        [fbDownloadStatus setObject:[NSNumber numberWithBool:NO] forKey:[contact objectID]];
                        
                        // Remove the key-value pair if contact has been dismissed
                        if (![self queue:contactAppearedQueue ContainsContact:contact] &&
                            ![self queue:contactNeverAppearedQueue ContainsContact:contact]) {
                            [fbDownloadStatus removeObjectForKey:[contact objectID]];
                        }
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:photoDownloadedNotification object:nil];
                }
                if (error) {
                    [DebugLogger log:[NSString stringWithFormat:@"Facebook download error: %@", [error userInfo]]
                        withPriority:mainViewControllerPriority];
                    abort();
                }

                // Remove the observer we just added -- we no longer need it
                [[NSNotificationCenter defaultCenter] removeObserver:thisController
                                                                name:NSManagedObjectContextDidSaveNotification
                                                              object:moc];
            }
        }
        @catch (NSException *exception) {
            [DebugLogger log:@"Facebook photo download error: thread probably temrinated mid execution"
                withPriority:mainViewControllerPriority];
        }
    });
}

#pragma mark - Registering for Notifications

- (void)registerForNotifications {
    UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types
                                                                             categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

#pragma mark - Tap Gestures

- (IBAction)deleteContactButton:(id)sender {
    [contactCard leftAction];
}

- (IBAction)checkContactButton:(id)sender {
    [self performSegueWithIdentifier:@"contact" sender:sender];
}

- (IBAction)postponeContactButton:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PickerViewController *pvc = [storyboard instantiateViewControllerWithIdentifier:@"picker"];
    [pvc setShouldHideCancelButton:NO];
    [pvc setPostponingContact:YES];
    [pvc setPostponingContactFromButton:YES];
    [pvc setDisplayedInMainView:YES];
    [pvc setContact:currentContact];
    [pvc setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [self presentViewController:pvc animated:YES completion:nil];
}

// Delete the current contact and refresh the queue
- (void)deleteContact {
    [DebugLogger log:@"Delete" withPriority:mainViewControllerPriority];
    
    ContactMetadata *metadata = (ContactMetadata *)[currentContact metadata];
    
    // Update metadata for contact
    NSDate *today = [NSDate date];
    [metadata setNoInterestDate:today];
    [metadata setInterest:[NSNumber numberWithBool:NO]];
    [metadata setNumTimesAppeared:[NSNumber numberWithInt:([[metadata numTimesAppeared] intValue] + 1)]];
    [self save];
    
    // Delete photo information to save space before dismissing contact
    [currentContact setFacebookPhoto:nil];
    [currentContact setLinkedinPhoto:nil];
    [self dismissContact];
}

// Switch between "appeared" and "never appeared queues
// When switching, we need to add the current contact back to the queue
- (IBAction)switchQueue:(id)sender {
    [DebugLogger log:@"Switching Queues" withPriority:mainViewControllerPriority];
    
    // Disable sliding cards while we change queues
    [self disableInteraction];
    [contactCard setUserInteractionEnabled:NO];
    
    // Switch queue
    if (currentQueue == contactAppearedQueue) {
        currentQueue = contactNeverAppearedQueue;
        [contactQueueView dismissQueueLeft];
    } else {
        currentQueue = contactAppearedQueue;
        [contactQueueView dismissQueueRight];
    }
}

#pragma mark - UI upating

// Show/hide the appropriate UI graphics depending on the current queue
- (void)updateUIForCurrentQueue:(NSNotification *)notification {
    if (currentQueue == contactAppearedQueue) {
        [switchQueueButton setImage:[UIImage imageNamed:@"eye_queue_open.png"] forState:UIControlStateNormal];
    } else {
        [switchQueueButton setImage:[UIImage imageNamed:@"eye_queue_closed.png"] forState:UIControlStateNormal];
    }
    if (!currentContact) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [contactActionButtonsView setAlpha:0];
                         }];

    } else {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [contactActionButtonsView setAlpha:1];
                         }];
    }
    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        [self enableInteraction];
    }
}

- (void)updateQueueWhileOffscreen {
    // Redraw the UI with information from the current queue
    [DebugLogger log:@"updating while offscreen" withPriority:mainViewControllerPriority];
    [self updateQueue];
    [contactCard showAndEnableInteraction];
    [self getNextContactFromQueue];
    [self updatePhotosDisplayedInQueue];
    [self printQueue];
}

// Display photos for contacts in the current queue
- (void)updatePhotosDisplayedInQueue {
    // If the current queue is empty
    if (!currentContact) {
        if (currentQueue == contactAppearedQueue) {
            [DebugLogger log:@"No reminders" withPriority:mainViewControllerPriority];
            [contactName setText:@"No Reminders"];
        } else {
            [DebugLogger log:@"No new contacts" withPriority:mainViewControllerPriority];
            [contactName setText:@"No New Contacts"];
        }
        
        // Hide the current queue
        [contactCard hideAndDisableInteraction];
        return;
    }
    
    // Set display name
    NSString *name = [NSString stringWithFormat:@"%@ %@", [currentContact nameFirst], [currentContact nameLast]];
    [contactName setText:name];
    
    // Draw the queue photos
    int i;
    for (i = 0; i < [currentQueue count] && i < 4; i++) {
        // Get queued contact id
        Contact *queuedContact = [currentQueue objectAtIndex:i];
        NSData *photoData = [queuedContact getPhotoData];
        UIImageView *queuedPhoto = [photoQueue objectAtIndex:i];
        UIImage *img;
        bool shouldUseDefaultPhoto = NO;
        if (!photoData) {
            shouldUseDefaultPhoto = YES;
        } else {
            // Use found data if resolution sufficiently high
            img = [[UIImage alloc] initWithData:photoData];
            NSInteger resolution = [img size].width * [img scale] + [img size].height * [img scale];
            if (resolution < RESOLUTION_THRESHOLD) {
                shouldUseDefaultPhoto = YES;
            }
        }
        
        // Set appropriate photo
        if (shouldUseDefaultPhoto) {
            NSString *defaultPhoto = [NSString stringWithFormat:@"default_profile_fade%d.png", i];
            img = [UIImage imageNamed:defaultPhoto];
        }
        [queuedPhoto setImage:img];
        [queuedPhoto setAlpha:1];
    }
    
    // In cases where we don't have a contact to put in the queue position, hide the photo all together
    for (; i < [photoQueue count]; i++) {
        UIImageView *queuedPhoto = [photoQueue objectAtIndex:i];
        [queuedPhoto setAlpha:0];
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

// Display "syncing contacts" message and sync contacts
- (void)displaySyncingViewAndSyncContacts {
    // Show the busy view
    [self disableInteraction];
    [DebugLogger log:@"Showing syncing view" withPriority:mainViewControllerPriority];
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [syncingView setAlpha:1];
        [syncingActivityIndicator startAnimating];
    } completion:^(BOOL finished) {
        [DebugLogger log:@"Start updating contacts" withPriority:mainViewControllerPriority];
        [ContactManager updateInformation];
        [self save];
        [UIView animateWithDuration:0.3 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [syncingView setAlpha:0];
        } completion:^(BOOL finished){
            [syncingActivityIndicator stopAnimating];
            
            // Populate the queues
            currentQueue = contactAppearedQueue;
            [self updateQueue];
            [self printQueue];

            // Switch to the unseen queue
            [self switchQueue:nil];

            // Request facebook access
            [self enableInteraction];
            [self registerForNotifications];
        }];
    }];
}

// Enable swiping/taping after animation ends
- (void)enableInteraction {
    [DebugLogger log:@"Enabling interaction" withPriority:mainViewControllerPriority];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

// Disable swiping/taping during animation
- (void)disableInteraction {
    [DebugLogger log:@"Disabling interaction" withPriority:mainViewControllerPriority];
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
}

#pragma mark - Navigation

// Passing information to ContactViewController before segueing
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Pass contact information to the new view controller.
    if ([[segue identifier] isEqualToString:@"contact"]) {
        [DebugLogger log:@"Preparing for segue to ContactViewController" withPriority:mainViewControllerPriority];
        ContactViewController *destViewController = [segue destinationViewController];
        [destViewController setContact:currentContact];
    }
    if ([[segue identifier] isEqualToString:@"tutorial"]) {
        [DebugLogger log:@"Preparing for segue to TutorialViewController" withPriority:mainViewControllerPriority];
        TutorialViewController *destViewController = [segue destinationViewController];
        [destViewController setMainViewController:sender];
    }
}

#pragma mark - Core Data Methods

- (GlobalData *)getGlobalDataEntity {
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"GlobalData" substitutionVariables:NULL];
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:@"Error getting globals" withPriority:mainViewControllerPriority];
        abort();
    }
    return [results objectAtIndex:0];
}

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
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Approve access to contacts"
                                                                                 message:@"Go to 'Settings > Privacy > Contacts' to change"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    CFRelease(addressBookRef);
}

// Merge NSManagedObjectContext changes across two different threads
- (void)mergeChanges:(NSNotification *)notification {
    [DebugLogger log:@"Got merge notification" withPriority:mainViewControllerPriority];
    [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
}

// Save current context
- (void)save {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate saveContext];
}

- (void)printQueue {
    NSLog(@"Printing queue");
    for (Contact *contact in currentQueue) {
        NSLog(@"%@", [contact nameFirst]);
    }
}

@end
