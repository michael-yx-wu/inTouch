//
//  ContactManager.m
//  inTouch
//
//  Created by Michael Wu on 4/22/14.
//  Copyright (c) 2014 inTouch Team. All rights reserved.
//

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
        
        // Get contact photo
        NSData *contactPhoto;
        if (ABPersonHasImageData(currentContact)) {
            contactPhoto = (__bridge_transfer NSData *)ABPersonCopyImageData(currentContact);
            [DebugLogger log:@"Got contact photo" withPriority:1];
        } else {
            [DebugLogger log:@"No contact photo" withPriority:1];
        }
        
        // Get home, other, and work emails
        // May need modify core data later to allow more email types
        ABMultiValueRef emails = ABRecordCopyValue(currentContact, kABPersonEmailProperty);
        NSString *emailHome, *emailOther, *emailWork, *emailLabel;
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
        // May need modify core data later to allow more phone number types
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(currentContact, kABPersonPhoneProperty);
        NSString *phoneHome, *phoneMobile, *phoneWork, *phoneLabel;
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
            // Fetch Contact and corresponding ContactMetadata
            NSArray *fetchResults = [self fetchRequestWithFirstName:firstName LastName:lastName];
            if ([fetchResults count] > 1) {
                [DebugLogger log:@"Did not update - multiple contacts with same name" withPriority:1];
            } else {
                contact = [fetchResults objectAtIndex:0];
                metaData = [contact valueForKey:@"metadata"];
                [DebugLogger log:[NSString stringWithFormat:@"Updating contact: %@ %@", firstName, lastName] withPriority:1];
            }
        }
        
        // Enter/update contact information
        [contact setValue:firstName forKey:@"nameFirst"];
        [contact setValue:lastName forKey:@"nameLast"];
        [contact setValue:contactPhoto forKey:@"contactPhoto"];
        [contact setValue:emailHome forKey:@"emailHome"];
        [contact setValue:emailOther forKey:@"emailOther"];
        [contact setValue:emailWork forKey:@"emailWork"];
        [contact setValue:phoneHome forKey:@"phoneHome"];
        [contact setValue:phoneMobile forKey:@"phoneMobile"];
        [contact setValue:phoneWork forKey:@"phoneWork"];
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
