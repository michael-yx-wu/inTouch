#import <CoreData/CoreData.h>

@interface GlobalData : NSManagedObject

@property (nonatomic, retain) NSString *accessToken;
@property (nonatomic, retain) NSNumber *firstContactTap;
@property (nonatomic, retain) NSNumber *firstLeftSwipe;
@property (nonatomic, retain) NSNumber *firstQueueSwitch;
@property (nonatomic, retain) NSNumber *firstRightSwipe;
@property (nonatomic, retain) NSNumber *firstRun;
@property (nonatomic, retain) NSDate *lastUpdatedInfo;
@property (nonatomic, retain) NSNumber *numContacts;
@property (nonatomic, retain) NSNumber *numLogins;
@property (nonatomic, retain) NSNumber *numNotInterested;

@end
