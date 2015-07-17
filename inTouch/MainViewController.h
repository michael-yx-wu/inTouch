#import "ContactCardView.h"
#import "ContactQueueView.h"

@interface MainViewController : UIViewController <MainViewDelegate>

// Current contact name and photo
@property (weak, nonatomic) IBOutlet ContactQueueView *contactQueueView;
@property (weak, nonatomic) IBOutlet ContactCardView *contactCard;
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoFront;

// Contact queues
@property (strong, nonatomic) NSMutableArray *contactNeverAppearedQueue;
@property (strong, nonatomic) NSMutableArray *contactAppearedQueue;
@property (strong, nonatomic) NSMutableDictionary *facebookFriends;
@property (weak, nonatomic) IBOutlet UIButton *switchQueueButton;

// Queue photos placeholders
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoMiddle;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoBottom;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoAnchor;

// User interaction
@property (weak, nonatomic) IBOutlet UIView *contactActionButtonsView;
@property (weak, nonatomic) IBOutlet UIView *deletedView;
@property (weak, nonatomic) IBOutlet UIView *postponedView;
@property (weak, nonatomic) IBOutlet UIView *syncingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *syncingActivityIndicator;

// Gesture recognizers
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *tapRecognizer;

- (void)requestContactsAccessAndSync;

@end