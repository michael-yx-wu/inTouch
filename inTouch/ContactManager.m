//
//  ContactManager.m
//  inTouch
//
//  Created by Michael Wu on 4/22/14.
//  Copyright (c) 2014 inTouch Team. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#import "AppDelegate.h"
#import "ContactManager.h"
#import "UrgencyCalculator.h"

#import "DebugLogger.h"

@implementation ContactManager

+ (void)updateInformation {
    [DebugLogger log:@"Updating Contacts..." withPriority:1];
    // Open contacts
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    NSArray *allContacts = (__bridge NSArray*)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    
    // Loop through contacts
    for (int i = 0; i < [allContacts count]; i++) {
        ABRecordRef currentContact = (__bridge ABRecordRef)[allContacts objectAtIndex:i];
        
        // Get name
        NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(currentContact, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(currentContact, kABPersonLastNameProperty);
        if (firstName == nil) firstName = @"";
        if (lastName == nil) lastName = @"";
        [DebugLogger log:[NSString stringWithFormat:@"First Name: %@", firstName] withPriority:1];
        [DebugLogger log:[NSString stringWithFormat:@"Last Name: %@", lastName] withPriority:1];
        
        // Get contact identifier
        NSNumber *abrecordid = [NSNumber numberWithInt:ABRecordGetRecordID(currentContact)];
        
        NSManagedObject *contact;
        NSManagedObject *metaData;
        
        // Create new contact if does not exist
        if ([[self fetchRequestWithFirstName:firstName LastName:lastName] count] == 0) {
            // Create Contact and ContactMetadata
            contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:[self managedObjectContext]];
            metaData = [NSEntityDescription insertNewObjectForEntityForName:@"ContactMetadata" inManagedObjectContext:[self managedObjectContext]];
            
            // Relate contact and metadata
            [contact setValue:metaData forKeyPath:@"metadata"];
            [metaData setValue:contact forKey:@"contact"];
            
            // Instantiate contact/metadata fields
            [contact setValue:firstName forKey:@"nameFirst"];
            [contact setValue:lastName forKey:@"nameLast"];
            [contact setValue:nil forKey:@"category"];
            [metaData setValue:[NSNumber numberWithInt:14] forKeyPath:@"freq"];
            [metaData setValue:[NSNumber numberWithBool:YES] forKey:@"interest"];
            [metaData setValue:nil forKey:@"lastContactedDate"];
            [metaData setValue:nil forKey:@"lastPostponedDate"];
            [metaData setValue:nil forKey:@"noInterestDate"];
            [metaData setValue:nil forKey:@"notes"];
            [metaData setValue:[NSNumber numberWithInteger:0] forKey:@"numTimesAppeared"];
            [metaData setValue:[NSNumber numberWithInteger:0] forKey:@"numTimesCalled"];
            [metaData setValue:[NSNumber numberWithInteger:0] forKey:@"numTimesContacted"];
            [metaData setValue:[NSNumber numberWithInteger:0] forKey:@"numTimesEmailed"];
            [metaData setValue:[NSNumber numberWithInteger:0] forKey:@"numTimesMessaged"];
            [metaData setValue:[NSNumber numberWithInteger:0] forKey:@"numTimesPostponed"];
            [metaData setValue:[[NSTimeZone localTimeZone] name] forKeyPath:@"timezone"];
            [metaData setValue:nil forKeyPath:@"urgency"];
            
            [DebugLogger log:[NSString stringWithFormat:@"Created Contact: %@ %@", firstName, lastName] withPriority:1];
        }
        
        // Update contact with current information
        else {
            // Fetch contact
            NSArray *fetchResults = [self fetchRequestWithFirstName:firstName LastName:lastName];
            if ([fetchResults count] > 1) {
                [DebugLogger log:@"Did not update - multiple contacts with same name" withPriority:1];
            } else {
                contact = [fetchResults objectAtIndex:0];
                [DebugLogger log:[NSString stringWithFormat:@"Updating contact: %@ %@", firstName, lastName] withPriority:1];
            }
        }
        
        // Update contact photo and id
        [contact setValue:abrecordid forKey:@"abrecordid"];
    }
    [self save];
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
+ (int)verifyABRecordID:(int)abrecordid forContact:(NSManagedObject*)contact {
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    // Get name
    ABRecordRef currentContact = ABAddressBookGetPersonWithRecordID(addressBookRef, abrecordid);
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
            NSString *someFirstName = (__bridge NSString*)ABRecordCopyValue(potentialMatch, kABPersonFirstNameProperty);
            NSString *someLastName = (__bridge NSString*)ABRecordCopyValue(potentialMatch, kABPersonLastNameProperty);
            if ([someFirstName isEqualToString:fname] && [someLastName isEqualToString:lname]) {
                newID = [NSNumber numberWithInt:ABRecordGetRecordID(potentialMatch)];
                [contact setValue:newID forKey:@"abrecorid"];
            }
            return [newID intValue];
        }
        [DebugLogger log:@"Error finding ID for contact" withPriority:1];
        abort();
    } else {
        return abrecordid;
    }
}

+ (void)updateUrgency {
    [UrgencyCalculator updateAll];
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
