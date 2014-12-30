#import "Contact.h"
#import <MessageUI/MessageUI.h>

@interface ContactInformationTableViewController : UITableViewController <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@property Contact *contact;

@end
