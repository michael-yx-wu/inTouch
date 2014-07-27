#import "Contact.h"

@interface ContactInformationTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneHomeLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneMobileLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneWorkLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailHomeLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailOtherLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailWorkLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *interestCell;
@property (weak, nonatomic) IBOutlet UILabel *interestLabel;
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (weak, nonatomic) IBOutlet UISlider *frequencySlider;
@property Contact *contact;

@end
