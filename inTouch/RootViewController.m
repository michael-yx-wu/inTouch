#import "RootViewController.h"

#import "AppDelegate.h"
#import "GlobalData.h"
#import "NotificationStrings.h"

#import "LoginViewController.h"
#import "MainViewController.h"

@implementation RootViewController

- (void)viewDidLoad {
    // Listener for successful login
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginSuccessful:)
                                                 name:inTouchLoginSuccessfulNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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
    GlobalData *globalData = [results objectAtIndex:0];
    if ([globalData accessToken] == nil) {
        [self performSegueWithIdentifier:@"login" sender:self];
    } else {
        [self performSegueWithIdentifier:@"mainView" sender:self];
    }
}

// Listen for successful login notification to present main view
- (void)loginSuccessful:(NSNotification *)notification {
    [self dismissViewControllerAnimated:NO completion:^{
        [self performSegueWithIdentifier:@"mainView" sender:self];
    }];
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
