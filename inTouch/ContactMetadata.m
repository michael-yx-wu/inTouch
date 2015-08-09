#import "ContactMetadata.h"

@implementation ContactMetadata

@dynamic daysBetweenReminder;
@dynamic interest;
@dynamic lastContactedDate;
@dynamic lastPostponedDate;
@dynamic noInterestDate;
@dynamic notes;
@dynamic numTimesAppeared;
@dynamic numTimesCalled;
@dynamic numTimesContacted;
@dynamic numTimesEmailed;
@dynamic numTimesMessaged;
@dynamic numTimesPostponed;
@dynamic remindOnDate;
@dynamic timezone;
@dynamic contact;

- (void)incrementTimesContacted:(ContactMethod)contactMethod {
    if (contactMethod == contactedByCall) {
        [self setNumTimesCalled:[NSNumber numberWithInt:[[self numTimesCalled] intValue]+1]];
    } else if (contactMethod == contactedByMessage) {
        [self setNumTimesMessaged:[NSNumber numberWithInt:[[self numTimesMessaged] intValue]+1]];
    } else if (contactMethod == contactedByEmail) {
        [self setNumTimesEmailed:[NSNumber numberWithInt:[[self numTimesEmailed] intValue]+1]];
    }
    [self setNumTimesContacted:[NSNumber numberWithInt:[[self numTimesContacted] intValue]+1]];
}

@end
