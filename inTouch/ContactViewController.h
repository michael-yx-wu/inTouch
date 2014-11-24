#import <CoreTelephony/CTCallCenter.h>

#import "Contact.h"

@interface ContactViewController : UIViewController

// Display
@property (weak, nonatomic) IBOutlet UIView *contactCard;
@property (nonatomic, weak) IBOutlet UILabel *contactName;
@property (nonatomic, weak) IBOutlet UIImageView *contactPhoto;
@property (nonatomic, weak) IBOutlet UIButton *callButton;
@property (nonatomic, weak) IBOutlet UIButton *messageButton;
@property (nonatomic, weak) IBOutlet UIButton *emailButton;

// Contact Data
@property (nonatomic, strong) Contact *contact;
@property (nonatomic, strong) UIImage *photoData;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *emailHome;
@property (nonatomic, strong) NSString *emailWork;
@property (nonatomic, strong) NSString *emailOther;
@property (nonatomic, strong) NSString *phoneHome;
@property (nonatomic, strong) NSString *phoneMobile;
@property (nonatomic, strong) NSString *phoneWork;

// Call center
@property (nonatomic, strong) CTCallCenter *callCenter;

@end

static NSString *phoneActionSheetTitle = @"Which number?";
static NSString *emailActionSheetTitle = @"Which email?";
static NSString *contactedCall = @"called";
static NSString *contactedMessage = @"messaged";
static NSString *contactedEmail = @"emailed";
static NSString *contactedGeneric = @"generic";
