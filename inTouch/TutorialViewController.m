#import "TutorialViewController.h"

#define NUM_TUTORIAL_PAGES 5

@implementation TutorialViewController

@synthesize viewControllers;
@synthesize doneButton;
@synthesize pageControl, pageViewController;
@synthesize mainViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    [pageControl setUserInteractionEnabled:NO];
    viewControllers = [[NSMutableArray alloc] initWithCapacity:5];
    pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                         navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                       options:nil];
    [pageViewController setDataSource:self];
    [pageViewController setDelegate:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
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
    [[self view] bringSubviewToFront:pageControl];
    [[self view] bringSubviewToFront:doneButton];
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

- (void)pageViewController:(UIPageViewController *)somePageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    if (completed) {
        NSUInteger index = [viewControllers indexOfObject:[[somePageViewController viewControllers] objectAtIndex:0]];
        [pageControl setCurrentPage:index];
        if (index == NUM_TUTORIAL_PAGES - 1) {
            [UIView animateWithDuration:0.3
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 [doneButton setAlpha:1];
                             } completion:nil];
        }
    }
}

// Sync contacts when the tutorial is dismissed
- (IBAction)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [mainViewController requestContactsAccessAndSync];
    }];
}

@end

