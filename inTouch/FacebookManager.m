#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "AppDelegate.h"
#import "FacebookManager.h"
#import "NotificationStrings.h"

static NSString *baseFriendsPath = @"me/taggable_friends?fields=name,picture.width(400).height(400)&limit=1000";

@implementation FacebookManager

+ (void)makeRequestWithPage:(NSString *)after dict:(NSMutableDictionary *)fbFriends {
    NSString *graphPath = baseFriendsPath;
    if (after) {
        graphPath = [NSString stringWithFormat:@"%@&after=%@", baseFriendsPath, after];
    }
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                                                   parameters:nil
                                                                   HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (error) {
            [DebugLogger log:[NSString stringWithFormat:@"Facebook friends request error: %@", [error userInfo]]
                withPriority:contactManagerPriority];
            return;
        }
        NSArray *taggableFriends = [result objectForKey:@"data"];
        for (NSDictionary *friend in taggableFriends) {
            NSString *name = [friend valueForKey:@"name"];
            NSArray *url = [[[friend valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"];
            [fbFriends setValue:url forKey:name];
        }

        NSDictionary *paging = [result objectForKey:@"paging"];
        if (![paging objectForKey:@"next"]) {
            NSDictionary *notificationData = @{@"data": fbFriends};
            [[NSNotificationCenter defaultCenter] postNotificationName:gotFacebookFriendsNotification
                                                                object:self
                                                              userInfo:notificationData];
        } else {
            NSDictionary *cursors = [paging objectForKey:@"cursors"];
            [self makeRequestWithPage:[cursors objectForKey:@"after"] dict:fbFriends];
        }
    }];
}

+ (void)getFriendsList {
    // Fail gracefully if no open session
    if (![self loggedIn]) {
        return;
    }

    __block NSMutableDictionary *fbFriends = [[NSMutableDictionary alloc] init];
    [self makeRequestWithPage:nil dict:fbFriends];
}

+ (BOOL)loggedIn {
    if ([FBSDKAccessToken currentAccessToken]) {
        return YES;
    }
    return NO;
}

+ (void)login {
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logInWithReadPermissions:@[@"public_profile", @"user_friends"]
                        fromViewController:nil
                                   handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                       [self handleLoginResult:result error:error];
                                   }];
}

+ (void)logout {
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logOut];
    [[NSNotificationCenter defaultCenter] postNotificationName:facebookSessionStateChanged object:nil];
}

+ (void)handleLoginResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    if (error) {
        [self showAlertViewWithTitle:[error localizedDescription] message:[error localizedRecoverySuggestion]];
        return;
    }

    if ([result token]) {
        [FBSDKAccessToken setCurrentAccessToken:[result token]];
        [[NSNotificationCenter defaultCenter] postNotificationName:facebookSessionStateChanged object:nil];
        [self getFriendsList];
    } else if ([result isCancelled]) {
        [self showAlertViewWithTitle:@"Login Cancelled" message:@"Login was cancelled by the user"];
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
                                                          AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                                          [[delegate alertWindow] setHidden:YES];;
                                                      }]];
    
    // Make the app delegate's alert window active and present the alert controller
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[delegate alertWindow] makeKeyAndVisible];
    [[[delegate alertWindow] rootViewController] presentViewController:alertController animated:YES completion:nil];
}

@end

