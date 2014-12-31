#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>
#import <MessageUI/MessageUI.h>

#import "Contact.h"

@interface ContactViewController : UIViewController <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate>

// Display
@property (weak, nonatomic) IBOutlet UIView *contactCard;
@property (nonatomic, weak) IBOutlet UILabel *contactName;
@property (nonatomic, weak) IBOutlet UIImageView *contactPhoto;
@property (nonatomic, weak) IBOutlet UIButton *callButton;
@property (nonatomic, weak) IBOutlet UIButton *messageButton;
@property (nonatomic, weak) IBOutlet UIButton *emailButton;

// Contact Data
@property (nonatomic, strong) Contact *contact;
@property (nonatomic, strong) NSDictionary *allEmailAddresses;
@property (nonatomic, strong) NSDictionary *allPhoneNumbers;

// Call center
@property (nonatomic, strong) CTCallCenter *callCenter;

@end