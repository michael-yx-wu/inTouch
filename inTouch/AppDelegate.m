//
//  AppDelegate.m
//  inTouch
//
//  Created by Michael Wu on 2/28/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>

#import "AppDelegate.h"
#import "UrgencyCalculator.h"

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

// Save changes to contacts before entering background
- (void)applicationWillResignActive:(UIApplication *)application {
    [self saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

// Upon becoming active application, check for new contacts to add/update
- (void)applicationDidBecomeActive:(UIApplication *)application {
}

// Save changes to contacts before termination
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
            abort();
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
