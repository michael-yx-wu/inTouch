#import <AddressBookUI/AddressBookUI.h>

#import "AppDelegate.h"
#import "ContactManager.h"
#import "GlobalData.h"

@implementation AppDelegate

@synthesize window;
@synthesize session;
@synthesize persistentStoreCoordinator;
@synthesize managedObjectModel;
@synthesize managedObjectContext;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Setting debug level to 1 (everything will be printed)
    [DebugLogger setDebugLevel:minimumPriorityThreshold];
    
    // Check if global data entity exists
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"GlobalData" substitutionVariables:NULL];
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:[NSString stringWithFormat:@"Fetch error: %@, %@",
                          error, [error userInfo]] withPriority:appDelegatePriority];
        abort();
    }
    
    // Create global data entity if does not exist
    if ([results count] == 0) {
        GlobalData *globalData = [NSEntityDescription insertNewObjectForEntityForName:@"GlobalData" inManagedObjectContext:moc];
        [globalData setLastUpdatedInfo:nil];
        [globalData setFirstRun:[NSNumber numberWithBool:YES]];
        [globalData setNumContacts:0];
        [globalData setNumLogins:0];
        [globalData setNumNotInterested:0];
    }
    
    // Load necessary FacebookSDK classes here
    [FBLoginView class];
    [FBAppCall class];
    [FBSession class];

    // Attempt to start facebook session on launch
    [self checkForFacebookSession];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Need to reset the contact queue
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearQueue" object:self];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Need to reset the contact queue
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearQueue" object:self];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActiveWithSession:session];
}

// Save changes to contacts before closing app
- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}

#pragma mark - Facebook

// Attempt to use cached facebook section
- (void)checkForFacebookSession {
    if ([[FBSession activeSession] state] == FBSessionStateCreatedTokenLoaded) {
        // Open silently
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                          // Handler for state changes
                                          [self sessionStateChanged:session state:status error:error];
                                      }];
    }
}

// Handle Facebook app response
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    BOOL handled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    return handled;
}

// Handle session state changes
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)status error:(NSError *)error {
    
}

#pragma mark - Core Data

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
        [DebugLogger log:@"Saved!" withPriority:appDelegatePriority];
    } else {
        [DebugLogger log:@"Nil moc!" withPriority:appDelegatePriority];
    }
}

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
        [DebugLogger log:[NSString stringWithFormat:@"Error: %@, %@", error, [error userInfo]] withPriority:appDelegatePriority];
        abort();
    }
    
    return persistentStoreCoordinator;
}

// Returns the URL to the application's Documents directory
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
