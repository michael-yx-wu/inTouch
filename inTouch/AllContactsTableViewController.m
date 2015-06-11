#import "AppDelegate.h"
#import "Contact.h"
#import "ContactInformationTableViewController.h"
#import "ContactMetadata.h"
#import "AllContactsTableViewController.h"

@interface AllContactsTableViewController () {
    Contact *selectedContact;
    NSMutableDictionary *contacts;
    NSMutableDictionary *contactIDs;
    NSMutableDictionary *contactCounts;
    NSMutableArray *sectionTitles;
}

@end

@implementation AllContactsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    contacts = [[NSMutableDictionary alloc] init];
    contactIDs = [[NSMutableDictionary alloc] init];
    contactCounts = [[NSMutableDictionary alloc] init];
    [[self tableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ContactCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    // Refresh contact list each time view will appear
    [self refreshContactList];
    
    // Get the section titles and manually put the hashtag section at the end
    sectionTitles = [NSMutableArray arrayWithArray:[[contactCounts allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
    if ([[sectionTitles objectAtIndex:0] isEqualToString:@"#"]) {
        [sectionTitles removeObjectAtIndex:0];
        [sectionTitles addObject:@"#"];
    }
    [[self tableView] reloadData];
}

- (void)refreshContactList {
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
    
    // Sort by first letter of name
    NSCharacterSet *alpha = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSZTUVWXYZ"];
    for (Contact *contact in results) {
        NSString *name = [NSString stringWithFormat:@"%@%@", [contact nameFirst], [contact nameLast]];
        NSString *abrecordid = [NSString stringWithFormat:@"%@", [contact abrecordid]];
        NSString *firstLetter;
        if (![name isEqualToString:@""]) {
            firstLetter = [[name substringToIndex:1] uppercaseString];
            NSRange i = [firstLetter rangeOfCharacterFromSet:alpha];
            if (i.location == NSNotFound) {
                firstLetter = @"#";
            }
        } else {
            firstLetter = @"#";
        }
        
        // Create a abrecordid array under the letter if one does not already exist
        if (![contactIDs objectForKey:firstLetter]) {
            [contactIDs setValue:[[NSMutableArray alloc] init] forKey:firstLetter];
        }
        
        // Add the contact
        [contacts setValue:contact forKey:abrecordid];
        NSMutableArray *nestedArray = [contactIDs valueForKey:firstLetter];
        [nestedArray addObject:abrecordid];
    }
    
    // Determine total number of rows needed for each section
    for (NSString *firstLetter in [contactIDs allKeys]) {
        [contactCounts setValue:[NSNumber numberWithInteger:[[contactIDs valueForKey:firstLetter] count]]
                         forKey:firstLetter];
    }
}

#pragma mark - Table view data source

// Return the number of sections.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sectionTitles count];
}

// Return the title for each section
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [sectionTitles objectAtIndex:section];
}

// Return the section index titles (right scroll)
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return sectionTitles;
}

// Return the number of rows in a section
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[contactCounts valueForKey:[sectionTitles objectAtIndex:section]] integerValue];
}

// Return the index of the section to jump to
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

// Fill cell with user name -- need to redo this
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Get contact/metadata by retrieving abrecordid associated with the indexPath
    NSString *sectionTitle = [sectionTitles objectAtIndex:[indexPath section]];
    NSString *contactID = [[contactIDs objectForKey:sectionTitle] objectAtIndex:[indexPath row]];
    Contact *contact = [contacts valueForKey:contactID];
    ContactMetadata *contactMetadata = (ContactMetadata *)[contact metadata];
    

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell" forIndexPath:indexPath];
    
    // Update cell text with name
    NSString *name = [NSString stringWithFormat:@"%@ %@", [contact nameFirst], [contact nameLast]];
    if ([name isEqualToString:@" "]) {
        name = @"No name";
    }
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
    NSString *sectionTitle = [sectionTitles objectAtIndex:[indexPath section]];
    NSString *contactID = [[contactIDs objectForKey:sectionTitle] objectAtIndex:[indexPath row]];
    selectedContact = [contacts valueForKey:contactID];

    [self performSegueWithIdentifier:@"contactInformation" sender:self];    
    
    // Release contacts
    contacts = [[NSMutableDictionary alloc] init];
    contactIDs = [[NSMutableDictionary alloc] init];
    contactCounts = [[NSMutableDictionary alloc] init];
    
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
    
    NSString *sectionTitle = [sectionTitles objectAtIndex:[indexPath section]];
    NSString *contactID = [[contactIDs objectForKey:sectionTitle] objectAtIndex:[indexPath row]];
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
