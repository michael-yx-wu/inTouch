#import "FacebookLoginViewController.h"

#import "DebugConstants.h"
#import "DebugLogger.h"

@interface FacebookLoginViewController ()
@end

@implementation FacebookLoginViewController

@synthesize fbLoginView;
@synthesize userLabel;
@synthesize profilePhoto;
@synthesize user;

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
    
    // Make contact photo round
    [[profilePhoto layer] setCornerRadius:profilePhoto.frame.size.width/2];
    [[profilePhoto layer] setMasksToBounds:YES];
    
    // Load in background image
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Facebook login logic

// Save user info after fetching
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)fbUser {
    NSLog(@"Logged in as %@ (%@)", [user name], [user objectID]);
    user = fbUser;
}

// User is currently logged in
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    // Fetch my profile photo -- if logged in
    [FBRequestConnection startWithGraphPath:@"me?fields=picture.height(500),picture.width(500)" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            [DebugLogger log:[NSString stringWithFormat:@"request error: %@", [error userInfo]] withPriority:facebookLoginViewControllerPriority];
            return;
        }
        
        // Parse results for profile photo url and download photo
        NSDictionary *picture = [[result valueForKeyPath:@"picture"] valueForKeyPath:@"data"];
        NSString *url = [picture valueForKeyPath:@"url"];
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
        [profilePhoto setImage:[UIImage imageWithData:imageData]];
    }];
    
    // Fetch name
    [FBRequestConnection startWithGraphPath:@"me?fileds=name" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            [DebugLogger log:[NSString stringWithFormat:@"request error: %@", error] withPriority:facebookLoginViewControllerPriority];
            return;
        }
        NSLog(@"%@", result);
        // Set name label text
        [userLabel setText:[result valueForKeyPath:@"name"]];
    }];
}

// User is currently logged out
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    // Clear the profile photo and reset the label
    [userLabel setText:nil];
    [profilePhoto setImage:[[UIImage alloc] init]];
}

@end
