#import "AppDelegate.h"
#import "FacebookManager.h"

@implementation FacebookManager

+ (BOOL)sessionOpen {
    // Return true if state is one of two possible session open states
    return ([[FBSession activeSession] state] == FBSessionStateOpen ||
            [[FBSession activeSession] state] == FBSessionStateOpenTokenExtended);
}

+ (void)getFriendsList {
    // Fail gracefully if no open session
    if (![self sessionOpen]) {
        return;
    }
    [FBRequestConnection startWithGraphPath:@"/me/taggable_friends?fields=name,picture.width(400).height(400)"
                          completionHandler:^(FBRequestConnection *connection,
                                              id result, NSError
                                              *error) {
                              NSMutableDictionary *fbFriends = [[NSMutableDictionary alloc] init];
                              if (error) {
                                  [DebugLogger log:[NSString stringWithFormat:@"request error: %@", [error userInfo]]
                                      withPriority:contactManagerPriority];
                              }
                              // Process facebook json object
                              NSArray *taggableFriends = [result objectForKey:@"data"];
                              for (NSDictionary *friend in taggableFriends) {
                                  NSString *name = [friend valueForKey:@"name"];
                                  NSArray *url = [[[friend valueForKey:@"picture"] valueForKey:@"data"]
                                                  valueForKey:@"url"];
                                  [fbFriends setValue:url forKey:name];
                              }
                              
                              // Post notification for MainViewController
                              NSDictionary *notificationData = @{@"data": fbFriends};
                              [[NSNotificationCenter defaultCenter] postNotificationName:@"facebookFriends"
                                                                                  object:self
                                                                                userInfo:notificationData];
                          }];
}

+ (void)login {
    [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                      AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
                                      [delegate sessionStateChanged:session state:status error:error];
                                  }];
}

+ (void)loginSilently {
    if ([[FBSession activeSession] state] == FBSessionStateCreatedTokenLoaded) {
        // Do not show login UI on fail
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                          // Handler for state changes
                                          [self sessionStateChanged:session state:status error:error];
                                      }];
    }
}

+ (void)logout {
    [[FBSession activeSession] closeAndClearTokenInformation];
}

+ (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)status error:(NSError *)error {
    // Session opened success
    if (!error && (status == FBSessionStateOpen || status == FBSessionStateOpenTokenExtended)) {
        [DebugLogger log:@"FB session opened" withPriority:appDelegatePriority];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fbSessionStateChanged" object:nil userInfo:nil];
        return;
    }
    
    // Session closed
    if (status == FBSessionStateClosed || status == FBSessionStateClosedLoginFailed) {
        [DebugLogger log:@"FB session closed or closed with login fail" withPriority:appDelegatePriority];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fbSessionStateChanged" object:nil userInfo:nil];
    }
    
    // Handle any errors
    if (error) {
        [DebugLogger log:@"FB session error" withPriority:appDelegatePriority];
        
        // If error requires users to do something outside of the app
        if ([FBErrorUtility shouldNotifyUserForError:error]) {
            [self showAlertViewWithTitle:@"Something went wrong"
                                 message:[FBErrorUtility userMessageForError:error]];
        } else {
            // Do nothing if user cancelled login
            if ([FBErrorUtility errorCategoryForError:error] ==  FBErrorCategoryUserCancelled) {
                [DebugLogger log:@"User cancelled FB login -- no action" withPriority:appDelegatePriority];
            }
            
            // Handle session closures that occured outside of app
            else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
                [self showAlertViewWithTitle:@"Facebook session error"
                                     message:@"Your current session is no longer valid. Please login again"];
            }
            
            // Handle generic errors
            else {
                // Get more information on error
                NSDictionary *errorInformation = [[[[error userInfo]
                                                    objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"]
                                                   objectForKey:@"body"] objectForKey:@"error"];
                [self showAlertViewWithTitle:@"Oops something went wrong!"
                                     message:[NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]]];
            }
        }
    }
}

+ (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Ok"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          // Hide app delegate's alert window
                                                          AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
                                                          [[delegate alertWindow] setHidden:YES];;
                                                      }]];
    
    // Make the app delegate's alert window active and present the alert controller
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [[delegate alertWindow] makeKeyAndVisible];
    [[[delegate alertWindow] rootViewController] presentViewController:alertController animated:YES completion:nil];
}

@end

