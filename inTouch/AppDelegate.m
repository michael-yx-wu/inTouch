#import "AppDelegate.h"
#import "ContactManager.h"
#import "FacebookManager.h"
#import "GlobalData.h"
#import "RootViewController.h"
#import "NotificationScheduler.h"
#import "NotificationStrings.h"

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

    
    // Check if global data entity exists
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"GlobalData"];
                               
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:[NSString stringWithFormat:@"Fetch error: %@, %@",
                          error, [error userInfo]] withPriority:appDelegatePriority];
        abort();
    }
    
    // Create global data entity if does not exist
    if ([results count] == 0) {
        GlobalData *globalData = [NSEntityDescription insertNewObjectForEntityForName:@"GlobalData"
                                                               inManagedObjectContext:moc];
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
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    // Post notification letting the mainViewController know that we finished registering for local notifications
    [[NSNotificationCenter defaultCenter] postNotificationName:registeredForNotifications object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Handles user leaving app while FB login dialog is being shown. Unresolved sessions are cleared on relaunch
//    [FBAppCall handleDidBecomeActive];

    // Dismiss all notifications (reschedule when resigning active)
    [NotificationScheduler dismissNotifications];

    // Log app activations
    [FBSDKAppEvents activateApp];
}

// Schedule notifications and save changes
- (void)applicationWillResignActive:(UIApplication *)application {
    [NotificationScheduler scheduleNotifications];
    [self saveContext];
}

#pragma mark - Facebook

// Handle session information 
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

#pragma mark - Core Data

// Save managed object context state if it has changed
- (void)saveContext {
    NSError *error;
    NSManagedObjectContext *moc = [self managedObjectContext];
    if (moc != nil) {
        // Attempt to save at most twice. Break on successful save.
        for (int i = 0; i < 2; i++) {
            if ([moc hasChanges] && ![moc save:&error]) {
                [DebugLogger log:[NSString stringWithFormat:@"Save error: %@, %@",
                                  error, [error userInfo]] withPriority:appDelegatePriority];
            } else {
                break;
            }
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

// Creates if necessary and returns the persistent store coordinator
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
