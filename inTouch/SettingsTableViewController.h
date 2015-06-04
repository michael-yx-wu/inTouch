@interface SettingsTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITableViewCell *facebookCell;
@property (weak, nonatomic) IBOutlet UILabel *facebookCellDetailLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *syncingContactsActivityIndicator;

@end
