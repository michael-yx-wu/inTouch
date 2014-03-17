//
//  AppDelegate.m
//  inTouch
//
//  Created by Michael Wu on 2/28/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>
#import "AppDelegate.h"
#import "DebugLogger.h"

@implementation AppDelegate

@synthesize persistentStoreCoordinator;
@synthesize managedObjectModel;
@synthesize managedObjectContext;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Setting debug level to 1 (everything will be printed)
    [DebugLogger setDebugLevel:1];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

// Upon becoming active application, check for new contacts to add/update
- (void)applicationDidBecomeActive:(UIApplication *)application {
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    // Add new contacts from AddressBook to CoreData
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted) {
                [self updateContacts];
            } else {
                // Display message - access denied
                UIAlertView *accessDeniedMessage = [[UIAlertView alloc]
                                                    initWithTitle:nil
                                                    message:@"Contacts were not automatically imported"
                                                    delegate:self
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
                [accessDeniedMessage show];
            }
        });
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        [self updateContacts];
    }
}

// Save changes to contacts before termination
- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}

#pragma mark - Update Contacts

// Iterate through contacts list and add new contacts to CoreData
- (void)updateContacts {
    [DebugLogger log:@"Updating Contacts..." withPriority:1];
    // Open contacts
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    NSArray *allContacts = (__bridge NSArray*)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    
    // Loop through contacts
    NSManagedObject *contact;
    for (int i = 0; i < [allContacts count]; i++) {
        ABRecordRef currentContact = (__bridge ABRecordRef)[allContacts objectAtIndex:i];
        
        // Get name
        NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(currentContact, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(currentContact, kABPersonLastNameProperty);
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
        
        // Check if contact already exists
        if ([[self fetchRequestWithFirstName:firstName LastName:lastName] count] == 0) {
            // Create ManageObject and populate with data
            // Note: some fields may be set to null
            contact = [NSEntityDescription
                       insertNewObjectForEntityForName:@"Contact"
                       inManagedObjectContext:[self managedObjectContext]];
            [contact setValue:firstName forKey:@"nameFirst"];
            [contact setValue:lastName forKey:@"nameLast"];
            [contact setValue:contactPhoto forKey:@"contactPhoto"];
            [contact setValue:emailHome forKey:@"emailHome"];
            [contact setValue:emailOther forKey:@"emailOther"];
            [contact setValue:emailWork forKey:@"emailWork"];
            [contact setValue:phoneHome forKey:@"phoneHome"];
            [contact setValue:phoneMobile forKey:@"phoneMobile"];
            [contact setValue:phoneWork forKey:@"phoneWork"];
            [DebugLogger log:@"Created entity for contact" withPriority:1];
        } else {
            [DebugLogger log:@"Contact already exists" withPriority:1];
        }
    }
}

// Returns an array of all entities with matching first and last names
// Will need to implement more sophisticated method of determing contact identity in the future
- (NSArray*)fetchRequestWithFirstName:(NSString*)fname LastName:(NSString*)lname {
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Contact"
                                                         inManagedObjectContext:moc];

    // Formulate the request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(nameFirst == %@) AND (nameLast == %@)",
                              fname, lname];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:[NSString stringWithFormat:@"Fetch error: %@, %@",
                          error, [error userInfo]] withPriority:1];
        abort();
    }
    return results;
}

// Return number of contacts in the current managed object context
- (NSUInteger)numContacts {
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Contact"
                                                         inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSError *error;
    NSUInteger count = [moc countForFetchRequest:request error:&error];
    if (count == NSNotFound) {
        [DebugLogger log:[NSString stringWithFormat:@"Fetch error: %@, %@",
                          error, [error userInfo]] withPriority:1];
    }
    return count;    
}

// Save managed object context state if it has changed
- (void)saveContext {
    NSError *error;
    NSManagedObjectContext *moc = [self managedObjectContext];
    if (moc != nil) {
        if ([moc hasChanges] && ![moc save:&error]) {
            [DebugLogger log:[NSString stringWithFormat:@"Save error: %@, %@", error, [error userInfo]] withPriority:1];
            abort();
        }
        [DebugLogger log:[NSString stringWithFormat:@"Total contacts: %lu", [self numContacts]] withPriority:1];
    }
}

#pragma mark - Core Data

// Creates if necessary and returns the managed object context
- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext;
}

// Creates if necessary and returns the managed object model
- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel) {
        return managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

// Creaes if necessary and returns the persistent store coordinator
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Model.sqlite"];

    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        [DebugLogger log:[NSString stringWithFormat:@"Error: %@, %@", error, [error userInfo]] withPriority:1];
        abort();
    }
    
    return persistentStoreCoordinator;
}

// Returns the URL to the application's Documents directory
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
@end
