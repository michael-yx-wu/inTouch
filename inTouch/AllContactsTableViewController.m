#import "AppDelegate.h"
#import "Contact.h"
#import "ContactInformationTableViewController.h"
#import "ContactMetadata.h"
#import "AllContactsTableViewController.h"

@interface AllContactsTableViewController () {
    Contact *selectedContact;
}

@end

@implementation AllContactsTableViewController

@synthesize contactIDs;
@synthesize contacts;
@synthesize alphabetIndices;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize the arrays
    contactIDs = [[NSMutableArray alloc] init];
    contacts = [[NSMutableDictionary alloc] init];
    
    // Set up the request to retrieve all contacts
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    NSDictionary *substitionVariables = [[NSDictionary alloc] init];
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"ContactAll" substitutionVariables:substitionVariables];
    
    // Sort by descending name
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nameFirst" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    // Fetch
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:[NSString stringWithFormat:@"Error getting next contact: %@, %@", error, [error userInfo]] withPriority:mainViewControllerPriority];
        abort();
    }
    
    for (Contact *contact in results) {
        [contactIDs addObject:[contact abrecordid]];
        [contacts setValue:contact forKeyPath:[NSString stringWithFormat:@"%@", [contact abrecordid]]];
    }

    [[self tableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ContactCell"];

    alphabetIndices = [self createAlphabetArray];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [[self tableView] reloadData];
    alphabetIndices = [self createAlphabetArray];
}

- (NSArray *)createAlphabetArray {
    NSMutableDictionary *firstLetters = [[NSMutableDictionary alloc] init];
    for (id key in [contacts allKeys]) {
        Contact *contact = [contacts objectForKey:key];
        NSString *name = [NSString stringWithFormat:@"%@%@", [contact nameFirst], [contact nameLast]];
        // Check for first letter only on non-empty strings
        if (![name isEqualToString:@""]) {
            NSString *firstLetter = [name substringToIndex:1];
            if (![firstLetters objectForKey:firstLetter]) {
                [firstLetters setValue:[NSNumber numberWithInt:1] forKey:firstLetter];
            }
        }
    }
    return [[firstLetters allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

#pragma mark - Table view data source

// Provide a localized table index
//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
//    return alphabetIndices;
//}

// Return the number of sections.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return [alphabetIndices count];
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [contacts count];
}

// Fill cell with user name
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Get contact/metadata by looking up associated abrecordid
    NSInteger row  = [indexPath row];
    NSString *contactID = [NSString stringWithFormat:@"%@", [contactIDs objectAtIndex:row]];
    Contact *contact = [contacts valueForKey:contactID];
    ContactMetadata *contactMetadata = (ContactMetadata *)[contact metadata];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell" forIndexPath:indexPath];
    
    // Update cell text with name
    NSString *name = [NSString stringWithFormat:@"%@ %@", [contact nameFirst], [contact nameLast]];
    [[cell textLabel] setText:name];
    
    // Get interest and set accessory appropriately
    UIButton *interestButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    if ([[contactMetadata interest] boolValue]) {
        
        [interestButton setImage:[UIImage imageNamed:@"interest_icon"] forState:UIControlStateNormal];
    } else {
        [interestButton setImage:[UIImage imageWithData:nil] forState:UIControlStateNormal];
    }
    [interestButton addTarget:self
                       action:@selector(interestButtonTapped:withEvent:)
             forControlEvents:UIControlEventTouchUpInside];
    [cell setAccessoryView:interestButton];
    return cell;
}

#pragma mark - Cell taps

// Show detailed contact information
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Get contact/metadata by looking up associated abrecordid
    NSInteger row  = [indexPath row];
    NSString *contactID = [NSString stringWithFormat:@"%@", [contactIDs objectAtIndex:row]];
    selectedContact = [contacts valueForKey:contactID];

    [self performSegueWithIdentifier:@"contactInformation" sender:self];    
    
    // Save change to database and refresh table
    [self save];
    [tableView reloadData];
}

- (void)interestButtonTapped:(id)sender withEvent:(UIEvent *)event {
    UIButton *interestButton = sender;
    NSIndexPath *indexPath = [[self tableView] indexPathForRowAtPoint:[[[event touchesForView:interestButton] anyObject] locationInView:[self tableView]]];
    if (indexPath == nil) {
        [DebugLogger log:@"nil index path" withPriority:allContactsTableViewControllerPriority];
        return;
    }
    
    NSInteger row  = [indexPath row];
    NSString *contactID = [NSString stringWithFormat:@"%@", [contactIDs objectAtIndex:row]];
    Contact *contact = [contacts valueForKey:contactID];
    ContactMetadata *contactMetadata = (ContactMetadata *)[contact metadata];
    
    // Toggle contact interest
    if ([[contactMetadata interest] boolValue]) {
        NSDate *today = [NSDate date];
        [contactMetadata setInterest:[NSNumber numberWithBool:NO]];
        [contactMetadata setNoInterestDate:today];
    } else {
        [contactMetadata setInterest:[NSNumber numberWithBool:YES]];
        [contactMetadata setNoInterestDate:NULL];
    }
    
    // Save change to database and refresh table
    [self save];
    [[self tableView] reloadData];
    
    [DebugLogger log:[NSString stringWithFormat:@"%@ %@ %@",
                      [[contactMetadata interest] boolValue] ? @"Interested in" : @"Not interested in",
                      [contact nameFirst],
                      [contact nameLast]]
        withPriority:allContactsTableViewControllerPriority];
}

# pragma mark - Navigation

// Passing selectedContact to ContactViewController before segueing
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [DebugLogger log:@"Preparing for segue to ContactViewController" withPriority:allContactsTableViewControllerPriority];
    
    // Pass contact information to the new view controller.
    if ([[segue identifier] isEqualToString:@"contactInformation"]) {
        ContactInformationTableViewController *destViewController = [segue destinationViewController];
        [destViewController setContact:selectedContact];
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

// Save current context
- (void)save {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate saveContext];
}

@end
