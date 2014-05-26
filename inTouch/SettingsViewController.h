

@interface SettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *busyView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet FBLoginView *fbLoginView;

@end
