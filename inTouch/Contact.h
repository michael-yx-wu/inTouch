#import "ContactMetadata.h"

@interface Contact : NSManagedObject

@property (nonatomic, retain) NSNumber * abrecordid;
@property (nonatomic, retain) NSNumber * category;
@property (nonatomic, retain) NSData * facebookPhoto;
@property (nonatomic, retain) NSData * linkedinPhoto;
@property (nonatomic, retain) NSString * nameFirst;
@property (nonatomic, retain) NSString * nameLast;
@property (nonatomic, retain) NSManagedObject *metadata;

- (NSData *)getPhotoData;

@end
