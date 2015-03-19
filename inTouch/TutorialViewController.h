#import "MainViewController.h"

@interface TutorialViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (weak, nonatomic) MainViewController *mainViewController;
@end
