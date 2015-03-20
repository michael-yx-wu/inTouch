#import "LoginViewController.h"

#import "AppDelegate.h"
#import "GlobalData.h"
#import "NotificationStrings.h"

#define SHIFT_PIXELS 80

@implementation LoginViewController

@synthesize formHighlight, signUpButton, loginButton;
@synthesize emailField, passwordField, verifyPasswordField;
@synthesize signUpForm;

- (void)viewDidLoad {
    signUpForm = YES;
    [emailField setDelegate:self];
    [passwordField setDelegate:self];
    [verifyPasswordField setDelegate:self];
    [self setReturnKeyForPasswordField];
    [passwordField setSecureTextEntry:YES];
    [verifyPasswordField setSecureTextEntry:YES];
    [verifyPasswordField setReturnKeyType:UIReturnKeyGo];
}

#pragma mark - Change forms

- (IBAction)signUpTapped:(id)sender {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self moveFormHighlight:true];
        [verifyPasswordField setAlpha:1];
    } completion:^(BOOL finished) {
        signUpForm = YES;
        [self setReturnKeyForPasswordField];
    }];
}

- (IBAction)loginTapped:(id)sender {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self moveFormHighlight:false];
        [verifyPasswordField setAlpha:0];
    } completion:^(BOOL finished) {
        signUpForm = NO;
        [self setReturnKeyForPasswordField];
    }];
}

- (void)moveFormHighlight:(BOOL)signup {
    CGRect highlightFrame = [formHighlight frame];
    CGRect buttonFrame;
    if (signup) {
        buttonFrame = [signUpButton frame];
    } else {
        buttonFrame = [loginButton frame];
    }
    CGRect newHighlightFrame = CGRectMake(buttonFrame.origin.x - 8,
                                          highlightFrame.origin.y,
                                          highlightFrame.size.width,
                                          highlightFrame.size.height);
    [formHighlight setFrame:newHighlightFrame];
}

- (void)setReturnKeyForPasswordField {
    if (signUpForm) {
        [passwordField setReturnKeyType:UIReturnKeyNext];
    } else {
        [passwordField setReturnKeyType:UIReturnKeyGo];
    }
    if ([passwordField isFirstResponder]) {
        [passwordField resignFirstResponder];
        [passwordField becomeFirstResponder];
    }
}

#pragma mark - Page shift

// Shift view up when user taps either text field
- (IBAction)shiftPageUp:(id)sender {
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         CGRect currentFrame = [[self view] frame];
                         [[self view] setFrame:CGRectMake(0,
                                                          -SHIFT_PIXELS,
                                                          currentFrame.size.width,
                                                          currentFrame.size.height)];
                     } completion:nil];
}

- (void)shiftPageDown {
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         CGRect currentFrame = [[self view] frame];
                         [[self view] setFrame:CGRectMake(0,
                                                          SHIFT_PIXELS,
                                                          currentFrame.size.width,
                                                          currentFrame.size.height)];
                     } completion:^(BOOL finished) {
                         [[NSNotificationCenter defaultCenter] postNotificationName:inTouchLoginSuccessfulNotification object:nil];
                     }];
}

#pragma mark - Login

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == emailField) {
        [passwordField becomeFirstResponder];
        return YES;
    } else if (textField == passwordField) {
        // Do not send a login request
        if (signUpForm) {
            [verifyPasswordField becomeFirstResponder];
        } else {
            [self attemptLogin];
        }
    }
    return YES;
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
        [self shiftPageDown];
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
