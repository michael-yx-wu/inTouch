//
//  AppDelegate.m
//  inTouch
//
//  Created by Michael Wu on 2/28/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>

#import "AppDelegate.h"
#import "ContactManager.h"
#import "UrgencyCalculator.h"

#import "DebugLogger.h"

@implementation AppDelegate

@synthesize persistentStoreCoordinator;
@synthesize managedObjectModel;
@synthesize managedObjectContext;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Setting debug level to 1 (everything will be printed)
    [DebugLogger setDebugLevel:1];
    
    // Create the GlobalData entity if it does not exist
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"GlobalData" substitutionVariables:NULL];
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:[NSString stringWithFormat:@"Fetch error: %@, %@",
                          error, [error userInfo]] withPriority:1];
        abort();
    }
    if ([results count] == 0) {
        NSManagedObject *globals = [NSEntityDescription insertNewObjectForEntityForName:@"GlobalData" inManagedObjectContext:moc];
        [globals setValue:nil forKey:@"lastUpdatedInfo"];
        [globals setValue:nil forKey:@"lastUpdatedUrgency"];
        [globals setValue:0 forKey:@"numContacts"];
        [globals setValue:0 forKey:@"numLogins"];
        [globals setValue:0 forKey:@"numNotInterested"];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

// Save changes to contacts before closing app
- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}

#pragma mark - Save implementation

// Save managed object context state if it has changed
- (void)saveContext {
    NSError *error;
    NSManagedObjectContext *moc = [self managedObjectContext];
    if (moc != nil) {
        if ([moc hasChanges] && ![moc save:&error]) {
            [DebugLogger log:[NSString stringWithFormat:@"Save error: %@, %@",
                              error, [error userInfo]] withPriority:1];
            
            // Keep trying until we successfully save -- is this safe?
            [self saveContext];
        }
        [DebugLogger log:@"Saved!" withPriority:1];
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
