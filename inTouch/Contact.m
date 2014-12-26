#import <AddressBookUI/AddressBookUI.h>

#import "Contact.h"
#import "ContactManager.h"
#import "ContactMetadata.h"

@implementation Contact

@dynamic abrecordid;
@dynamic category;
@dynamic facebookPhoto;
@dynamic linkedinPhoto;
@dynamic nameFirst;
@dynamic nameLast;
@dynamic metadata;

- (NSData *)getPhotoData {
    NSData *photoData;
    NSData *facebookPhoto = [self facebookPhoto];
    NSData *linkedinPhoto = [self linkedinPhoto];
    if (facebookPhoto != NULL) {
        photoData = facebookPhoto;
    } else if (linkedinPhoto != NULL) {
        photoData = linkedinPhoto;
    } else {
        int abrecordid = [ContactManager verifyABRecordID:[[self abrecordid] intValue] forContact:self];
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
        ABRecordRef addressBookContact = ABAddressBookGetPersonWithRecordID(addressBookRef, abrecordid);
        if (ABPersonHasImageData(addressBookContact)) {
            photoData = (__bridge_transfer NSData *)ABPersonCopyImageData(addressBookContact);
        } else {
            UIImage *img = [UIImage imageNamed:@"default_profile_fade0.png"];
            photoData = UIImagePNGRepresentation(img);
        }
        CFRelease(addressBookRef);
    }
    return photoData;
}

@end
