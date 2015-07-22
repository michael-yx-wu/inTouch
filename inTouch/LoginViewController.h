/*!
 @header LoginViewController.h
 
 @brief Contains the LoginViewController class.
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

/*!
 @class LoginViewController
 
 @brief Controls the login and signup view. 
 
 @superclass UIViewController
 */

@interface LoginViewController : UIViewController <UITextFieldDelegate, NSURLConnectionDataDelegate>

/*!
 @brief TRUE if the signup button is highlighted. FALSE is the login button is highlighted.
 */
@property (nonatomic) BOOL signUpForm;

/*!
 @group Form selection
 */

/*!
 @brief A small rectangular UIView that highlights the signup or login buttons, letting the user know what action is 
        being attempted.
 */
@property (weak, nonatomic) IBOutlet UIView *formHighlight;

/*!
 @brief The signup button.
 */
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;

/*!
 @brief The login button.
 */
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

/*!
 @group Text fields
 */

/*!
 @brief The email text field.
 */
@property (weak, nonatomic) IBOutlet UITextField *emailField;

/*!
 @brief The password text field.
 */
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

/*!
 @brief The verify password text field.
 */
@property (weak, nonatomic) IBOutlet UITextField *verifyPasswordField;

@end
