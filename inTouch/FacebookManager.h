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
 @brief Method to check Facebook login status.
 */
+ (BOOL)loggedIn;

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
 @brief Clear token information and logout.
 */
+ (void)logout;

@end
