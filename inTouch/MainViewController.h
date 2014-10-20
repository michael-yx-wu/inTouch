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
@property (weak, nonatomic) IBOutlet UIView *updatingUrgencyView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *updatingUrgencyActivityIndicator;

// Gesture recognizers
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *tapRecognizer;

// Current contact remind frequency
@property (weak, nonatomic) IBOutlet UISlider *frequencySlider;
@property (weak, nonatomic) IBOutlet UILabel *viewFrequency;

// Current contact attributes in core data
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSData *photoData;
@property int abrecordid;
@property (strong, nonatomic) NSString *emailHome;
@property (strong, nonatomic) NSString *emailOther;
@property (strong, nonatomic) NSString *emailWork;
@property (strong, nonatomic) NSString *phoneHome;
@property (strong, nonatomic) NSString *phoneMobile;
@property (strong, nonatomic) NSString *phoneWork;
@property (strong, nonatomic) NSDate *lastContactedDate;

// Contact queue stuff
@property (strong, nonatomic) NSMutableArray *contactQueue;
@property (strong, nonatomic) NSMutableDictionary *facebookFriends;
@end
