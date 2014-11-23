#import "ContactCardView.h"

@interface MainViewController : UIViewController <MainViewDelegate>

// Current contact name and photo
@property (weak, nonatomic) IBOutlet ContactCardView *contactCard;
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoFront;

// Queue photos
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoMiddle;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoBottom;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoAnchor;

// User interaction
@property (weak, nonatomic) IBOutlet UIView *deletedView;
@property (weak, nonatomic) IBOutlet UIView *postponedView;
@property (weak, nonatomic) IBOutlet UIView *syncingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *syncingActivityIndicator;

// Gesture recognizers
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *tapRecognizer;

// Contact queue stuff
@property (strong, nonatomic) NSMutableArray *contactNeverAppearedQueue;
@property (strong, nonatomic) NSMutableArray *contactAppearedQueue;
@property (strong, nonatomic) NSMutableDictionary *facebookFriends;

@end
