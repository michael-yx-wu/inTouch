@interface LoginViewController : UIViewController <UITextFieldDelegate, NSURLConnectionDataDelegate>

@property (weak, nonatomic) IBOutlet UIView *formHighlight;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *verifyPasswordField;
@property (nonatomic) BOOL signUpForm;

@end
