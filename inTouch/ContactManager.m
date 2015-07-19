#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#import "AppDelegate.h"
#import "ContactManager.h"
#import "Contact.h"
#import "ContactMetadata.h"
#import "FacebookManager.h"
#import "NotificationStrings.h"

@implementation ContactManager

NSInteger kFacebookRequestBegin = 1;
NSInteger kFacebookRequestFinish = 0;

+ (void)updateInformation{
    [DebugLogger log:@"Updating Contacts..." withPriority:1];
    // Open contacts
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    NSArray *allContacts = (__bridge_transfer NSArray*)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    
    // Loop through contacts
    for (int i = 0; i < [allContacts count]; i++) {
        ABRecordRef currentContact = (__bridge ABRecordRef)[allContacts objectAtIndex:i];
        
        // Get name
        NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(currentContact, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(currentContact, kABPersonLastNameProperty);
        if (firstName == nil) firstName = @"";
        if (lastName == nil) lastName = @"";
        [DebugLogger log:[NSString stringWithFormat:@"First Name: %@", firstName] withPriority:contactManagerPriority];
        [DebugLogger log:[NSString stringWithFormat:@"Last Name: %@", lastName] withPriority:contactManagerPriority];
        
        // Get contact identifier
        NSNumber *abrecordid = [NSNumber numberWithInt:ABRecordGetRecordID(currentContact)];
        
        Contact *contact;
        ContactMetadata *metaData;
        
        // Create new contact if does not exist
        if ([[self fetchRequestWithFirstName:firstName LastName:lastName] count] == 0) {
            // Create Contact and ContactMetadata
            contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:[self managedObjectContext]];
            metaData = [NSEntityDescription insertNewObjectForEntityForName:@"ContactMetadata" inManagedObjectContext:[self managedObjectContext]];
            
            // Relate contact and metadata
            [contact setMetadata:metaData];
            [metaData setContact:contact];
            
            // Instantiate contact/metadata fields
            [contact setNameFirst:firstName];
            [contact setNameLast:lastName];
            [contact setCategory:nil];
            
            [metaData setDaysBetweenReminder:[NSNumber numberWithInt:0]];
            [metaData setInterest:[NSNumber numberWithBool:YES]];
            [metaData setNumTimesAppeared:[NSNumber numberWithInt:0]];
            [metaData setNumTimesCalled:[NSNumber numberWithInt:0]];
            [metaData setNumTimesContacted:[NSNumber numberWithInt:0]];
            [metaData setNumTimesEmailed:[NSNumber numberWithInt:0]];
            [metaData setNumTimesMessaged:[NSNumber numberWithInt:0]];
            [metaData setNumTimesPostponed:[NSNumber numberWithInt:0]];
            [metaData setLastContactedDate:nil];
            [metaData setLastPostponedDate:nil];
            [metaData setNoInterestDate:nil];
            [metaData setNotes:nil];
            [metaData setRemindOnDate:nil];
            [metaData setTimezone:[[NSTimeZone localTimeZone] name]];
            
            [DebugLogger log:[NSString stringWithFormat:@"Created Contact: %@ %@", firstName, lastName] withPriority:1];
        }
        
        // Update contact with current information
        else {
            // Fetch contact
            NSArray *fetchResults = [self fetchRequestWithFirstName:firstName LastName:lastName];
            if ([fetchResults count] > 1) {
                [DebugLogger log:@"Did not update - multiple contacts with same name" withPriority:contactManagerPriority];
            } else {
                contact = [fetchResults objectAtIndex:0];
                [DebugLogger log:[NSString stringWithFormat:@"Updating contact: %@ %@", firstName, lastName] withPriority:contactManagerPriority];
            }
        }
        
        // Update contact id
        [contact setAbrecordid:abrecordid];
    }
    [self save];
    
    // Attempt to refresh facebook friend list
    [FacebookManager getFriendsList];
    
    // Clean up
    CFRelease(addressBookRef);
}

// Returns an array of all entities with matching first and last names
// Will need to implement more sophisticated method of determing contact identity in the future
+ (NSArray*)fetchRequestWithFirstName:(NSString*)fname LastName:(NSString*)lname {
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    
    // ContactNameMatch - return all contacts that match first name AND last name fields
    NSDictionary *subVars = @{
                              @"NAMEFIRST": fname,
                              @"NAMELAST": lname
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

// Return the correct ABRecordID for the contact
+ (int)verifyABRecordIDForContact:(Contact *)contact {
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    // Get name
    ABRecordRef currentContact = ABAddressBookGetPersonWithRecordID(addressBookRef, [[contact abrecordid] intValue]);
    NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(currentContact, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(currentContact, kABPersonLastNameProperty);
    if (firstName == nil) firstName = @"";
    if (lastName == nil) lastName = @"";
    
    NSString *fname = [contact valueForKey:@"nameFirst"];
    NSString *lname = [contact valueForKey:@"nameLast"];
    
    // Verify name match
    if (![firstName isEqualToString:fname] || ![lastName isEqualToString:lname]) {
        CFStringRef name = (__bridge CFStringRef)lname;
        NSNumber *newID;
        NSArray *matches = (__bridge_transfer NSArray*)ABAddressBookCopyPeopleWithName(addressBookRef, name);
        for (int i = 0; i < [matches count]; i++) {
            ABRecordRef potentialMatch = (__bridge ABRecordRef)[matches objectAtIndex:i];
            NSString *someFirstName = (__bridge_transfer NSString*)ABRecordCopyValue(potentialMatch, kABPersonFirstNameProperty);
            NSString *someLastName = (__bridge_transfer NSString*)ABRecordCopyValue(potentialMatch, kABPersonLastNameProperty);
            if ([someFirstName isEqualToString:fname] && [someLastName isEqualToString:lname]) {
                newID = [NSNumber numberWithInt:ABRecordGetRecordID(potentialMatch)];
                [contact setValue:newID forKey:@"abrecorid"];
            }            
            CFRelease(addressBookRef);
            return [newID intValue];
        }
        [DebugLogger log:@"Error finding ID for contact" withPriority:contactManagerPriority];
        abort();
    } else {
        CFRelease(addressBookRef);
        return [[contact abrecordid] intValue];
    }
}

#pragma mark - Core Data Accessor Methods

+ (NSManagedObjectContext *)managedObjectContext {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate managedObjectContext];
}

+ (NSManagedObjectModel *)managedObjectModel {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate managedObjectModel];
}

+ (void)save {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate saveContext];
}

@end
