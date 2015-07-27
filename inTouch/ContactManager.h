/*!
 @header Contact.h
 
 @brief Contains the ContactManager static class.
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

#import "Contact.h"

/*!
 @class ContactManager
 
 @brief Static class used to facilitate basic operations on Contact objects.
 
 @superclass NSObject
 
 @see Contact
 */
@interface ContactManager : NSObject

/*!
 @brief Update Core Data with the latest list of contacts from the address book.
 
 @discussion This function is used to sync contacts on first launch as well as update contacts manually.
 */
+ (void)updateInformation;

/*!
 @brief Verify and retrieve the ABRecordID of the current contact.
 
 @discussion Some quick notes on the use of ABRecordID to identify contacts: 
 
             Every record in the Address Book database has a unique record identifier (ABRecordID). This identifier
             always refers to the same record, unless that record is deleted or the data is reset. Record identifiers
             can be safely passed between threads. They are not guaranteed to remain the same across devices.
 
             The recommended way to keep a long-term reference to a particular record is to store the first and last
             name, or a hash of the first and last name, in addition to the identifier. 
             When you look up a record by ID, compare the record’s name to your stored name. If they don’t match, use 
             the stored name to find the record, and store the new ID for the record.
 
             The information above is provided by Apple in their Address Book programming guide for iOS. Because the
             ABRecordID is not a failsafe way to find contacts, contact first and last names are used to verify (and if
             necessary, to lookup) the ABRecordID of a contact.
 
 @param contact The contact for whom we want to retrieve an ABRecordID.
 
 @return Returns the correct ABRecordID of the contact. If the contact cannot be found, abort.
 
 @warning Should implement graceful failure.
 */
+ (int)verifyABRecordIDForContact:(Contact *)contact;

@end