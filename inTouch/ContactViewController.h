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
@property (nonatomic, strong) NSMutableDictionary *allEmailAddresses;
@property (nonatomic, strong) NSMutableDictionary *allPhoneNumbers;

// Call center
@property (nonatomic, strong) CTCallCenter *callCenter;

@end