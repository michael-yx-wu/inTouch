#import "AppDelegate.h"
#import "GlobalData.h"

#import "LoginViewController.h"
#import "MainViewController.h"

#define SHIFT_PIXELS 50

@implementation LoginViewController

@synthesize emailField, passwordField;

- (void)viewDidLoad {
    [emailField setDelegate:self];
    [passwordField setDelegate:self];
    [passwordField setSecureTextEntry:YES];
    [emailField setReturnKeyType:UIReturnKeyNext];
    [passwordField setReturnKeyType:UIReturnKeyDone];
}

// Shift view up when user taps either text field
- (IBAction)shiftPageUp:(id)sender {
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         CGRect currentFrame = [[self view] frame];
                         [[self view] setFrame:CGRectMake(0, -SHIFT_PIXELS, currentFrame.size.width, currentFrame.size.height)];
                     } completion:^(BOOL finished) {
                         
                     }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == emailField) {
        [passwordField becomeFirstResponder];
        return YES;
    } else if (textField == passwordField) {
        [self attemptLogin];
    }
    return NO;
}

- (void)attemptLogin {
    NSURL *url = [NSURL URLWithString:@"https://52.11.149.45:3000/users/sign_in"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSDictionary *requestData = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 [emailField text], @"email",
                                 [passwordField text], @"password",
                                 nil];
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:requestData options:0 error:&error];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSError *error;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    NSLog(@"%@", jsonDict);
    if ([jsonDict valueForKey:@"success"]) {
        NSManagedObjectContext *moc = [self managedObjectContext];
        NSManagedObjectModel *model = [self managedObjectModel];
        NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"GlobalData" substitutionVariables:NULL];
        
        NSError *error;
        NSArray *results = [moc executeFetchRequest:request error:&error];
        if (results == nil) {
            [DebugLogger log:@"Error getting globals" withPriority:mainViewControllerPriority];
            abort();
        }
        GlobalData *globalData = [results objectAtIndex:0];
        [globalData setAccessToken:[jsonDict valueForKey:@"message"]];
        [self save];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        MainViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"main"];
        [mainViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        [self presentViewController:mainViewController animated:YES completion:nil];
        
        
    }
}

#pragma mark - Ignore self-signed cert

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        // Only trust our own domain
        if ([[[challenge protectionSpace] host] isEqualToString:@"52.11.149.45"]) {
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        }
    }
    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod
            isEqualToString:NSURLAuthenticationMethodServerTrust];
}

#pragma mark - Core Data Methods

- (NSManagedObjectContext *)managedObjectContext {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate managedObjectContext];
}

- (NSManagedObjectModel *)managedObjectModel {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate managedObjectModel];
}

// Save current context
- (void)save {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate saveContext];
}

@end
