#import "TutorialViewController.h"

#define NUM_TUTORIAL_PAGES 5

@implementation TutorialViewController

@synthesize pageViewController;
@synthesize viewControllers;

- (void)viewDidLoad {
    [super viewDidLoad];
    viewControllers = [[NSMutableArray alloc] initWithCapacity:5];
    pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                         navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                       options:nil];
    [pageViewController setDataSource:self];
}

- (void)viewDidLayoutSubviews {
    CGRect frame = [[self view] frame];
    [[pageViewController view] setFrame:frame];
    
    for (int i = 1; i <= NUM_TUTORIAL_PAGES; i++) {
        UIViewController *viewController = [[UIViewController alloc] init];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
        [imageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"tutorial%d", i]]];
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        [[viewController view] addSubview:imageView];
        [viewControllers addObject:viewController];
    }
    [pageViewController setViewControllers:@[[viewControllers objectAtIndex:0]]
                                 direction:UIPageViewControllerNavigationDirectionForward
                                  animated:NO
                                completion:nil];
    [self addChildViewController:pageViewController];
    [[self view] addSubview:[pageViewController view]];
    [pageViewController didMoveToParentViewController:self];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = [viewControllers indexOfObject:viewController];
    if (index == 0) {
        return nil;
    } else {
        return [viewControllers objectAtIndex:(index - 1)];
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = [viewControllers indexOfObject:viewController];
    if (index == NUM_TUTORIAL_PAGES - 1) {
        return nil;
    } else {
        return [viewControllers objectAtIndex:(index + 1)];
    }
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return NUM_TUTORIAL_PAGES;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return 0;
}

@end

