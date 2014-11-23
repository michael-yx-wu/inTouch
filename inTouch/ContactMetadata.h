#import "Contact.h"

@interface ContactMetadata : NSManagedObject

@property (nonatomic, retain) NSNumber * interest;
@property (nonatomic, retain) NSDate * lastContactedDate;
@property (nonatomic, retain) NSDate * lastPostponedDate;
@property (nonatomic, retain) NSDate * noInterestDate;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSNumber * numTimesAppeared;
@property (nonatomic, retain) NSNumber * numTimesCalled;
@property (nonatomic, retain) NSNumber * numTimesContacted;
@property (nonatomic, retain) NSNumber * numTimesEmailed;
@property (nonatomic, retain) NSNumber * numTimesMessaged;
@property (nonatomic, retain) NSNumber * numTimesPostponed;
@property (nonatomic, retain) NSDate * remindOnDate;
@property (nonatomic, retain) NSString * timezone;
@property (nonatomic, retain) NSManagedObject *contact;

@end
