#import "RootViewController.h"

#import "AppDelegate.h"
#import "GlobalData.h"
#import "NotificationStrings.h"

#import "LoginViewController.h"
#import "MainViewController.h"

@implementation RootViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self performSegueWithIdentifier:@"mainView" sender:self];
    
    /* Hotfix: disable login screen until we have account-specific content  */
    
//    // Check if global data entity exists
//    NSManagedObjectContext *moc = [self managedObjectContext];
//    NSManagedObjectModel *model = [self managedObjectModel];
//    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"GlobalData" substitutionVariables:NULL];
//    
//    NSError *error;
//    NSArray *results = [moc executeFetchRequest:request error:&error];
//    if (results == nil) {
//        [DebugLogger log:[NSString stringWithFormat:@"Fetch error: %@, %@",
//                          error, [error userInfo]] withPriority:appDelegatePriority];
//        abort();
//    }
//    GlobalData *globalData = [results objectAtIndex:0];
//    if ([globalData accessToken] == nil) {
//        [DebugLogger log:@"Not logged in: showing login view" withPriority:rootViewControllerPriority];
//        [self performSegueWithIdentifier:@"login" sender:self];
//    } else {
//        [DebugLogger log:[NSString stringWithFormat:@"Access token: %@", [globalData accessToken]]
//            withPriority:rootViewControllerPriority];
//        [self performSegueWithIdentifier:@"mainView" sender:self];
//    }
}

#pragma mark - Core Data accessor methods

- (NSManagedObjectContext *)managedObjectContext {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate managedObjectContext];
}

- (NSManagedObjectModel *)managedObjectModel {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate managedObjectModel];
}

@end
