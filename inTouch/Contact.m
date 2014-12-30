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
        int abrecordid = [ContactManager verifyABRecordIDForContact:self];
        [self setAbrecordid:[NSNumber numberWithInt:abrecordid]];
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

- (NSDictionary *)getPhoneNumbers {
    [DebugLogger log:@"Getting all linked numbers" withPriority:contactCardViewPriority];
    int abrecordid = [ContactManager verifyABRecordIDForContact:self];
    [self setAbrecordid:[NSNumber numberWithInt:abrecordid]];
    
    NSMutableDictionary *allPhoneNumbers = [[NSMutableDictionary alloc] init];
    NSMutableSet *seenPhoneNumbers = [[NSMutableSet alloc] init];
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef addressBookContact = ABAddressBookGetPersonWithRecordID(addressBookRef, abrecordid);
    CFArrayRef linkedAddressBookContacts = ABPersonCopyArrayOfAllLinkedPeople(addressBookContact);
    
    ABRecordRef linkedAddressBookContact;
    ABMultiValueRef phoneNumbers;
    for (CFIndex i = 0; i < CFArrayGetCount(linkedAddressBookContacts); i++) {
        linkedAddressBookContact = CFArrayGetValueAtIndex(linkedAddressBookContacts, i);
        phoneNumbers = ABRecordCopyValue(linkedAddressBookContact, kABPersonPhoneProperty);
        
        // Loop through linked contact's phone numbers and add everything to allPhoneNumbers
        for (CFIndex j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
            // Strip number of irrelevant characters. Only international code and digits are necessary
            NSString *phoneNumber = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            phoneNumber = [[phoneNumber componentsSeparatedByCharactersInSet:
                            [[NSCharacterSet characterSetWithCharactersInString:@"+0123456789"] invertedSet]]
                           componentsJoinedByString:@""];
            
            // Only add this phone number label pair if we have not yet seen this number
            if (![seenPhoneNumbers containsObject:phoneNumber]) {
                [seenPhoneNumbers addObject:phoneNumber];
                NSString *label = (__bridge_transfer NSString*)ABMultiValueCopyLabelAtIndex(phoneNumbers, j);
                label = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)label);
                if ([label isEqualToString:@""]) {
                    label = @"other";
                }
                [allPhoneNumbers setObject:phoneNumber forKey:label];
            }
        }
        CFRelease(phoneNumbers);
    }
    CFRelease(linkedAddressBookContacts);
    CFRelease(addressBookRef);
    return allPhoneNumbers;
}

- (NSDictionary *)getEmails {
    [DebugLogger log:@"Getting all linked emails" withPriority:contactCardViewPriority];
    int abrecordid = [ContactManager verifyABRecordIDForContact:self];
    [self setAbrecordid:[NSNumber numberWithInt:abrecordid]];
    
    NSMutableDictionary *allEmailAddresses = [[NSMutableDictionary alloc] init];
    NSMutableSet *seenEmailAddresses = [[NSMutableSet alloc] init];
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef addressBookContact = ABAddressBookGetPersonWithRecordID(addressBookRef, abrecordid);
    CFArrayRef linkedAddressBookContacts = ABPersonCopyArrayOfAllLinkedPeople(addressBookContact);
    
    ABRecordRef linkedAddressBookContact;
    ABMultiValueRef emails;
    for (CFIndex i = 0; i < CFArrayGetCount(linkedAddressBookContacts); i++) {
        linkedAddressBookContact = CFArrayGetValueAtIndex(linkedAddressBookContacts, i);
        emails = ABRecordCopyValue(linkedAddressBookContact, kABPersonEmailProperty);
        
        // Loop through linked contact's phone numbers and add everything to allPhoneNumbers
        for (CFIndex j = 0; j < ABMultiValueGetCount(emails); j++) {
            NSString *email = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, j);
            
            // Only add this email label pair if we have not yet seen this email
            if (![seenEmailAddresses containsObject:email]) {
                [seenEmailAddresses addObject:email];
                NSString *label = (__bridge_transfer NSString*)ABMultiValueCopyLabelAtIndex(emails, j);
                label = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)label);
                if ([label isEqualToString:@""]) {
                    label = @"other";
                }
                [allEmailAddresses setObject:email forKey:label];
            }
        }
        CFRelease(emails);
    }
    CFRelease(linkedAddressBookContacts);
    CFRelease(addressBookRef);
    return allEmailAddresses;
}

@end
