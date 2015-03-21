#import <AddressBookUI/AddressBookUI.h>

#import "AppDelegate.h"
#import "ContactManager.h"
#import "FacebookManager.h"
#import "GlobalData.h"

#import "RootViewController.h"

@implementation AppDelegate

@synthesize window;
@synthesize alertWindow;
@synthesize persistentStoreCoordinator, managedObjectModel, managedObjectContext;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DebugLogger setDebugLevel:minimumPriorityThreshold];
    
    // Set the root view controller
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RootViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"root"];
    [[self window] setRootViewController:rootViewController];
    [[self window] makeKeyAndVisible];
    
    // Create a hidden window to allow us to display facebook login errors from any view
    UIWindow *alertContainer = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [alertContainer setWindowLevel:UIWindowLevelStatusBar];
    [alertContainer setBackgroundColor:[UIColor clearColor]];
    [alertContainer setHidden:YES];
    [self setAlertWindow:alertContainer];
    [alertContainer setRootViewController:[[UIViewController alloc] init]];

    // Attempt to start facebook session on launch
    [FacebookManager loginSilently];
    
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
        [globalData setAccessToken:nil];
        [globalData setLastUpdatedInfo:nil];
        [globalData setFirstContactTap:[NSNumber numberWithBool:YES]];
        [globalData setFirstLeftSwipe:[NSNumber numberWithBool:YES]];
        [globalData setFirstQueueSwitch:[NSNumber numberWithBool:YES]];
        [globalData setFirstRightSwipe:[NSNumber numberWithBool:YES]];
        [globalData setFirstRun:[NSNumber numberWithBool:YES]];
        [globalData setNumContacts:0];
        [globalData setNumLogins:0];
        [globalData setNumNotInterested:0];
    }
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Handles user leaving app while FB login dialog is being shown. Unresolved sessions are cleared on relaunch
    [FBAppCall handleDidBecomeActive];
}

// Save changes to contacts before closing app
- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}

#pragma mark - Facebook

// Handle session information 
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // Handler block may be lost when app terminated due to low memory -- must explicitly set block
    // This will produce a log message saying that the handler is being overwritten. 
    [[FBSession activeSession] setStateChangeHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        [FacebookManager sessionStateChanged:session state:status error:error];
    }];
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
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
