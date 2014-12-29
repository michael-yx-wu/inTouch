#import "MainViewController.h"

@interface ContactManager : NSObject

+ (void)updateInformation;
+ (int)verifyABRecordIDForContact:(Contact *)contact;

@end