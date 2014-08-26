#import "Contact.h"

@interface ContactCard : UIView

// Data
@property Contact *contact;

@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhoto;

@end
