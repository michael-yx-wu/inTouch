@interface LoginViewController : UIViewController <UITextFieldDelegate, NSURLConnectionDataDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (nonatomic) BOOL shiftedUp;

@end
