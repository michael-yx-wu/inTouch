#import <UIKit/UIKit.h>

@interface FacebookLoginViewController : UIViewController <FBLoginViewDelegate>

@property (weak, nonatomic) IBOutlet FBLoginView *fbLoginView;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePhoto;
@property (strong, nonatomic) id<FBGraphUser> user;

@end
