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

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Setting debug level to 1 (everything will be printed)
    [DebugLogger setDebugLevel:1];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types
    // of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application
    // and it begins the transition to the background state. Use this method to pause ongoing tasks, disable timers, and
    // throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state
    // information to restore your application to its current state in case it is terminated later. If your application
    // supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
}

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

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// Iterate through contacts list and add new contacts to CoreData
- (void)updateContacts {
    [DebugLogger log:@"Updating Contacts..." withPriority:1];
    // Open contacts
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    NSArray *allContacts = (__bridge NSArray*)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    
    // Loop through contacts
    NSManagedObjectModel *contact;
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
        
        // Get home, mobile, and work phone numbers
        // May need modify core data later to allow more phone number types
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(currentContact, kABPersonPhoneProperty);
        NSString *phoneHome, *phoneMobile, *phoneWork, *phoneLabel;
        CFStringRef label;
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
        
        // Get home, other, and work emails
        // May need modify core data later to allow more email types
        ABMultiValueRef emails = ABRecordCopyValue(currentContact, kABPersonEmailProperty);
        NSString *emailHome, *emailOther, *emailWork, *emailLabel;
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
    }
}

@end
