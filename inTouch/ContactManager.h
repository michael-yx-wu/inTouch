@interface ContactManager : NSObject

+ (void)updateInformation;
+ (void)updateUrgency;
+ (int)verifyABRecordID:(int)abrecordid forContact:(NSManagedObject*)contact;

@end