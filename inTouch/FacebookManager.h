@interface FacebookManager : NSObject

// Check if the session is in one of two possible open states
+ (BOOL)sessionOpen;

// Uses the taggable_friends endpoint to get a list of the user's friends. List is passed off to MainViewController
+ (void)getFriendsList;

// Log in to facebook
+ (void)login;

// Attempts to login using cached token. Does nothing on failure
+ (void)loginSilently;

// Clear token information and log out
+ (void)logout;

// Handle changed session states
+ (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)status error:(NSError *)error;

@end
