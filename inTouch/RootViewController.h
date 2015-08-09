/*!
 @header RootViewController.h
 
 @brief Contains the RootViewController class
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

/*!
 @class RootViewController
 
 @brief Determines whether to show the LoginViewController or the MainViewController.
 
 @discussion Currently seguing directly to the MainViewController. LoginViewController is being bypassed until we can
             demonstrate to the Apple App Review Team a clear need for users to have accounts.
 
 @superclass UIViewController
 */
@interface RootViewController : UIViewController

@end
