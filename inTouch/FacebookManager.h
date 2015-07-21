/*!
 @header FacebookManager.h
 
 @brief Contains the Facebookmanager static class.
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

/*!
 @class FacebookManager
 
 @brief Handles Facebook API related functions.
 
 @discussion Responsible for Facebook logins and logouts. Also responsible for displaying relevant Facebook-related
             alerts. Alerts are displayed on a UIWindow that is normally hidden from view. When an alert is being 
             presented, this UIWindow is temporarily made visible. After the alert is dismissed, this UIWindow is 
             hidden once more.
 
 @superclass NSObject
 
 @see AppDelegate
 */
@interface FacebookManager : NSObject

/*!
 @brief Check if the current session is in one of two states: FBSessionStateOpen or FBSessionStateTokenExtended
 
 @return Return true if the current session is in the FBSessionStateOpen or FBSessionStateTokenExtended states.
 */
+ (BOOL)sessionOpen;

/*!
 @brief Use the taggable_friends Graph API endpoint to get a list of the user's friends. 
 
 @discussion Depending on a user's friends' privacy settings, this list may not be comprehensive.
 */
+ (void)getFriendsList;

/*!
 @brief Log in to Facebook by briefly opening a Safari window.
 */
+ (void)login;

/*!
 @brief Attempt to log in to Facebook using a cached token.
 
 @discussion Does not open Safari on failure.
 */
+ (void)loginSilently;

/*!
 @brief Clear token information and logout.
 */
+ (void)logout;

/*!
 @brief Handle Facebook session state changes.
 
 @discussion On nominal session state changes, posts a notification to let the SettingsViewController update the label
             appropriately. When unexpected errors occur, display an alert to the users. These alerts can be shown
             regardless of the current state of the application because they are displayed on the AppDelegate's 
             UIWindow that is normally hidden.
 
 @param session The current Facebook session.
 @param status The current Facebook session status.
 @param error Errors are written to this variable.
 */
+ (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)status error:(NSError *)error;

@end
