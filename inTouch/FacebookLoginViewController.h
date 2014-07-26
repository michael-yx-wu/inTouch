#import <UIKit/UIKit.h>

@interface FacebookLoginViewController : UIViewController <FBLoginViewDelegate>

@property (weak, nonatomic) IBOutlet FBLoginView *fbLoginView;

@end
