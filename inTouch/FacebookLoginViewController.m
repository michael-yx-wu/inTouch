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

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)fbUser {
}

// User is currently logged in
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    // Get my profile picture
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"false", @"redirect",
                            @"400", @"height",
                            @"large", @"type",
                            @"400", @"width",
                            nil
                            ];
    [FBRequestConnection startWithGraphPath:@"/me/picture"
                                 parameters:params
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              if (error) {
                                  [DebugLogger log:[NSString stringWithFormat:@"request error: %@", [error userInfo]] withPriority:facebookLoginViewControllerPriority];
                                  return;
                              }
                              NSString *url = [[result valueForKeyPath:@"data"] valueForKeyPath:@"url"];
                              NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
                              [profilePhoto setImage:[UIImage imageWithData:imageData]];
                          }];
    
    // Get my name
    [FBRequestConnection startWithGraphPath:@"me?fields=name" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            [DebugLogger log:[NSString stringWithFormat:@"request error: %@", error] withPriority:facebookLoginViewControllerPriority];
            return;
        }
        [userLabel setText:[result valueForKeyPath:@"name"]];
    }];
    
    // Populate fbFriends with facebook friend names and url - this is so ugly right now (indentation is killing me)
    [FBRequestConnection startWithGraphPath:@"/me/taggable_friends?fields=name,picture.width(400).height(400)"
                          completionHandler:^(FBRequestConnection *connection,
                                              id result, NSError
                                              *error) {
                              NSMutableDictionary *fbFriends = [[NSMutableDictionary alloc] init];
                              if (error) {
                                  [DebugLogger log:[NSString stringWithFormat:@"request error: %@", [error userInfo]]
                                      withPriority:contactManagerPriority];
                              }
                              // Process facebook json object
                              NSArray *taggableFriends = [result objectForKey:@"data"];
                              for (NSDictionary *friend in taggableFriends) {
                                  NSString *name = [friend valueForKey:@"name"];
                                  NSArray *url = [[[friend valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"];
                                  [fbFriends setValue:url forKey:name];
                              }
                              
                              // Post notification for mainViewController
                              NSDictionary *notificationData = @{@"data": fbFriends};
                              [[NSNotificationCenter defaultCenter] postNotificationName:@"facebookFriends"
                                                                                  object:self
                                                                                userInfo:notificationData];
                          }];
}

// User is currently logged out
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    // Clear the profile photo and reset the label
    [userLabel setText:@"Sync Contact Photos"];
    [profilePhoto setImage:[UIImage imageNamed:@"default_pf_v2"]];
}

@end
