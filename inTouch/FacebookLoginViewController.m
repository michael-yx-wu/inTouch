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
    
    // Populate fbFriends with facebook friend names and url - this is so ugly right now (indentation is killing me)
    [FBRequestConnection startWithGraphPath:@"/me/taggable_friends?fields=name,picture.width(500),picture.height(500)"                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        NSMutableDictionary *fbFriends = [[NSMutableDictionary alloc] init];
        if (error) {
            [DebugLogger log:[NSString stringWithFormat:@"request error: %@", [error userInfo]] withPriority:contactManagerPriority];
        }
        
        // Process facebook json object
        NSArray *taggableFriends = [result objectForKey:@"data"];
        for (NSDictionary *friend in taggableFriends) {
            NSString *name = [friend valueForKey:@"name"];
            NSArray *picture = [friend valueForKey:@"picture"];
            NSArray *pictureData = [picture valueForKey:@"data"];
            NSString *url = [NSString stringWithString:[pictureData valueForKey:@"url"]];
            [fbFriends setValue:url forKey:name];
        }
        
        // Post notification for mainViewController
        NSDictionary *notificationData = @{@"data": fbFriends};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"facebookFriends" object:self userInfo:notificationData];
    }];
}

// User is currently logged out
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    // Clear the profile photo and reset the label
    [userLabel setText:@"Sync Contact Photos"];
    [profilePhoto setImage:[UIImage imageNamed:@"default_pf_v2"]];
}

@end
