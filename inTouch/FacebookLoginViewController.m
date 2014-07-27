#import "FacebookLoginViewController.h"

@interface FacebookLoginViewController ()
@end

@implementation FacebookLoginViewController

@synthesize fbLoginView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [fbLoginView setDelegate:self];
    
    // Set default Facebook login behavior
    [fbLoginView setLoginBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent];
    
    // Load in background image
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Facebook login logic

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user {
    NSLog(@"Logged in as %@(%@)", [user name], [user objectID]);
}

@end
