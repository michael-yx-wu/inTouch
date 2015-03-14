@interface TutorialViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@end
