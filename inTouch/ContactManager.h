#import "MainViewController.h"

@interface ContactManager : NSObject

+ (void)updateInformation;
+ (int)verifyABRecordID:(int)abrecordid forContact:(NSManagedObject*)contact;

@end