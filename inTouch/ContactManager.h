#import "Contact.h"

@interface ContactManager : NSObject

+ (void)updateInformation;
+ (int)verifyABRecordIDForContact:(Contact *)contact;

@end