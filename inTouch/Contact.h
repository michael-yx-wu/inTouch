/*!
 @header Contact.h
 
 @brief Contains the subclass for the Contact entity in Core Data.
 
 @discussion The subclass below makes it easier to interact with the Contact entity in Core Data.
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

#import "ContactMetadata.h"

/*!
 @class Contact
 
 @brief Subclass for the Contact entity in Core Data.
 
 @discussion This subclass makes it easier to interact with the Contact entity in Core Data.
 
 @see ContactMetadata
 
 @superclass NSManagedObject
 */
@interface Contact : NSManagedObject

/*! 
 @brief ABRecordID of the contact.

 @discussion ABRecordID is not necessarily consistent over time. When using it to fetch a record, it is recommended to
             make sure that contact details (e.g. first and last name) are as expected.
 */
@property (nonatomic, retain) NSNumber *abrecordid;

/*! 
 @brief Category of the contact.
    
 @discussion Used to sort contacts into different categories.
 
 @warning Not currently being used in any feature of the application.
 */
@property (nonatomic, retain) NSNumber *category;

/*!
 @brief Facebook photo data of the contact.
 */
@property (nonatomic, retain) NSData *facebookPhoto;

/*!
 @brief LinkedIn photo data of the contact.
 
 @warning Not currently being used in any feature fo the application.
 */
@property (nonatomic, retain) NSData *linkedinPhoto;

/*!
 @brief First name of the contact.
 */
@property (nonatomic, retain) NSString *nameFirst;

/*!
 @brief Last name of the contact.
 */
@property (nonatomic, retain) NSString *nameLast;

/*!
 @brief A pointer to the @link ContactMetadata @/link entity associated with this contact.
 */
@property (nonatomic, retain) NSManagedObject *metadata;

/*!
 @brief Get contact photo data. Preference (in descending order) is Facebook, LinkedIn, AddressBook.
 
 @returns NSData of the contact photo.
 */
- (NSData *)getPhotoData;

/*!
 @brief Get all phone numbers (including phone numbers listed under linked contacts) associated with this contact.
 
 @discussion Numbers that are listed more than once (e.g. under multiple linked contacts) will not be duplicated in the
             results.
 
 @returns NSDictionary with phone number labels as keys and phone numbers as values. Labels and phone numbers are both
 stored as NSString.
 */
- (NSDictionary *)getPhoneNumbers;

/*!
 @brief Get all emails (including emails listed under linked contacts) associated with this contact.
 
 @discussion Emails that are listed more than once (e.g. under multiple linked contacts) will not be duplicated in the
             results.
 
 @returns NSDictionary with email labels as keys and emails as values. Labels and emails are both stored as NSString.
 */
- (NSDictionary *)getEmails;

@end
