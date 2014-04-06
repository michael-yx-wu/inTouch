//
//  ViewController.m
//  inTouch
//
//  Created by Naicheng Wangyu on 03/01/14.
//  Copyright (c) 2014 Naicheng Wangyu. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "ContactViewController.h"

#import "DebugLogger.h"

@interface MainViewController ()
@end

@implementation MainViewController

// Contact display variables
@synthesize contactName;
@synthesize contactPhoto;
@synthesize viewFrequency;

// Contact data variables
@synthesize firstName;
@synthesize lastName;
@synthesize photoData;
@synthesize emailHome;
@synthesize emailOther;
@synthesize emailWork;
@synthesize phoneHome;
@synthesize phoneMobile;
@synthesize phoneWork;

- (void)viewDidLoad {
    [super viewDidLoad];
    
	// Alertview with basic instructions.
    UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:@"Quick How-to Guide"
                                                      message:@"Swipe up to email \n Swipe left to text message \n Swipe right to postpone \n Swipe down to remove from future reminders\n"
                                                     delegate:self
                                            cancelButtonTitle:@"Got it"
                                            otherButtonTitles:nil, nil];
    [myAlert show];
    [self performSelector:@selector(getNextContact) withObject:nil afterDelay:2];
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

// Button for "manually contacted" someone, that's not a swipe action.
- (IBAction)manuallyContacted:(id)sender {
    [DebugLogger log:@"Manually contacted current contact" withPriority:1];
    // Update the global count, time, and other values in the core model.
    
    
}

// Get the most urgent contact in the database
- (void)getNextContact {
    // Set up the request
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    NSDictionary *substitionVariables = [[NSDictionary alloc] init];
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"ContactMetadataUrgent" substitutionVariables:substitionVariables];
    
    // Sort by descending urgency and limit to 1 result
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"urgency" ascending:false];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    [request setFetchLimit:1];
    
    // Fetch
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:[NSString stringWithFormat:@"Error getting next contact: %@, %@", error, [error userInfo]] withPriority:2];
    }
    
    // Get next urgent contact information if exists
    if ([results count] == 0) {
        [[self contactName] setText:@"No Urgent Contacts"];
    }
    else {
        NSManagedObject *contact = [[results objectAtIndex:0] valueForKey:@"Contact"];
        firstName = [contact valueForKey:@"nameFirst"];
        lastName = [contact valueForKey:@"nameLast"];
        photoData = [contact valueForKey:@"contactPhoto"];
        emailHome = [contact valueForKey:@"emailHome"];
        emailOther = [contact valueForKey:@"emailOther"];
        emailWork = [contact valueForKey:@"emailWork"];
        phoneHome = [contact valueForKey:@"phoneHome"];
        phoneMobile = [contact valueForKey:@"phoneMobile"];
        phoneWork = [contact valueForKey:@"phoneWork"];
        
        // Set display name
        NSString *name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        [contactName setText:name];
        
        // Set contact photo
        UIImage *img = [[UIImage alloc] initWithData:photoData];
        [contactPhoto setImage:img];
    }
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

#pragma mark - Navigation
- (IBAction)swipeLeft:(id)sender {
    [DebugLogger log:@"Swiped Left" withPriority:2];
    if (![[contactName text] isEqualToString:@"No Urgent Contacts"]) {
        [self performSegueWithIdentifier:@"contact" sender:sender];
    }
}

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

@end
