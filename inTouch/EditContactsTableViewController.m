#import "AppDelegate.h"
#import "Contact.h"
#import "ContactInformationTableViewController.h"
#import "ContactMetadata.h"
#import "EditContactsTableViewController.h"

#import "DebugLogger.h"
#import "DebugConstants.h"

@interface EditContactsTableViewController () {
    Contact *selectedContact;
}

@end

@implementation EditContactsTableViewController

@synthesize contactIDs;
@synthesize contacts;
@synthesize alphabetIndices;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if ([[contactMetadata interest] intValue]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    return cell;
}

// Show detailed contact information
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    // Get contact/metadata by looking up associated abrecordid
    NSInteger row  = [indexPath row];
    NSString *contactID = [NSString stringWithFormat:@"%@", [contactIDs objectAtIndex:row]];
    selectedContact = [contacts valueForKey:contactID];

    [self performSegueWithIdentifier:@"contactInformation" sender:self];    
    
    // Save change to database and refresh table
    [self save];
    [tableView reloadData];
    
}

// Toggle interest on accessory select -- this will only work after we throw a transparent uiview on top of the
// tableview to intercept touch events. This is messy, but the only way we can have this custom functionality 
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    // Get contact/metadata by looking up associated abrecordid
    NSInteger row  = [indexPath row];
    NSString *contactID = [NSString stringWithFormat:@"%@", [contactIDs objectAtIndex:row]];
    Contact *contact = [contacts valueForKey:contactID];
    ContactMetadata *contactMetadata = (ContactMetadata *)[contact metadata];
    
    // Toggle contact interest
    if ([[contactMetadata interest] intValue]) {
        NSDate *today = [NSDate date];
        [contactMetadata setInterest:[NSNumber numberWithBool:NO]];
        [contactMetadata setNoInterestDate:today];
    } else {
        [contactMetadata setInterest:[NSNumber numberWithBool:YES]];
        [contactMetadata setNoInterestDate:NULL];
    }
    
    // Save change to database and refresh table
    [self save];
    [tableView reloadData];
}

# pragma mark - Navigation

// Passing selectedContact to ContactViewController before segueing
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [DebugLogger log:@"Preparing for segue to ContactViewController" withPriority:editContactsTableViewControllerPriority];
    
    // Pass contact information to the new view controller.
    if ([[segue identifier] isEqualToString:@"contactInformation"]) {
        ContactInformationTableViewController *destViewController = [segue destinationViewController];
        [destViewController setContact:selectedContact];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
