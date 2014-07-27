#import <UIKit/UIKit.h>

@interface EditContactsTableViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray *contactIDs;
@property (strong, nonatomic) NSMutableDictionary *contacts;

@end
