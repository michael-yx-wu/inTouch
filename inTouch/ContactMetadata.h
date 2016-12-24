/*!
 @header ContactMetadata.h
 
 @brief Contains the subclass for the ContactMetadata entity in Core Data.
 
 @discussion The subclass below makes it easier to interact with the ContactMetadata entity in Core Data.
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

#import "Contact.h"

/*!
 @class ContactMetadata
 
 @brief Subclass for the ContactMetadata entity in Core Data.
 
 @discussion This class makes it easier to interact with the ContactMetadata entity in Core Data.
 
 @see Contact
 
 @superclass NSManagedObject
 */
@interface ContactMetadata : NSManagedObject

/*!
 @brief Default number of days till next reminder.
 
 @discussion This is the value that the PickerViewController will display when it is brought up.
 */
@property (nonatomic, retain) NSNumber *daysBetweenReminder;

/*!
 @brief Boolean value representing whether or not we wish to see this contact in the future.
 */
@property (nonatomic, retain) NSNumber *interest;

/*!
 @brief Date on which contact was last contacted.
 */
@property (nonatomic, retain) NSDate *lastContactedDate;

/*!
 @brief Date on which contact was last postponed.
 */
@property (nonatomic, retain) NSDate *lastPostponedDate;

/*!
 @brief Date on which interest was set to NO.
 */
@property (nonatomic, retain) NSDate *noInterestDate;

/*!
 @brief Brief comments or notes about the contact.
 
 @warning Not currently being used in any feature of the application.
 */
@property (nonatomic, retain) NSString *notes;

/*!
 @brief Total number of times this contact has appeared.
 
 @discussion Appearing in the 'unseen queue' also counts as an appearance.
 */
@property (nonatomic, retain) NSNumber *numTimesAppeared;

/*!
 @brief Total number of times this contact has been called.
 */
@property (nonatomic, retain) NSNumber *numTimesCalled;

/*!
 @brief Total number of times this contact has been contacted.
 
 @discussion This is equal to the sum of numTimesAppeared, numTimesEmailed, numTimesMessaged, and any number of times
             in which the user tapped the 'manually contacted' button. The number of taps of the 'manually contacted' button are not directly recorded.
 */
@property (nonatomic, retain) NSNumber *numTimesContacted;

/*!
 @brief Total number of times this contact has been emailed.
 */
@property (nonatomic, retain) NSNumber *numTimesEmailed;

/*!
 @brief Total number of times this contact has been messaged.
 */
@property (nonatomic, retain) NSNumber *numTimesMessaged;

/*!
 @brief Total number of times this contact has been postponed.
 */
@property (nonatomic, retain) NSNumber *numTimesPostponed;

/*!
 @brief The timezone this contact belongs to.
 
 @warning Not currently being used in any feature of the application.
 */
@property (nonatomic, retain) NSString *timezone;

/*!
 @brief A number that represents that relative likelihood of this contact appearing.
 
 @discussion The maximum value is 1 and represents a contact being equally as likely to appear as other contacts.
             0.01 is the minimum instead of 0 because we don't want to effective prevent a contact from appearing
             because it's been postponed too many times.
 */
@property (nonatomic, retain) NSNumber *weight;

/*!
 @brief A pointer to the Contact entity associated with this ContactMetadata.
 */
@property (nonatomic, retain) NSManagedObject *contact;


/*!
 @typedef ContactMethod
 
 @brief Describes the ways in which the Contact associated with this ContactMetadata was contacted.
 
 @field contactedByCall Contacted via calling
 @field contactedByMessage Contacted via message
 @field contactedByEmail Contacted via email
 @field contactedManually Contacted by tapping the 'manually contacted' button
 */
typedef enum : NSInteger {
    contactedByCall,
    contactedByMessage,
    contactedByEmail,
    contactedManually
} ContactMethod;

/*!
 @brief Increment the number of times the Contact associated with this ContactMetadata was contacted.
 
 @discussion The numTimesContacted property in incremented. numTimesCalled, numTimesMessaged, and numTimesEmailed may be
             incremented depending on the value of contactMethod.
 
 @param contactMethod The method of contact.
 
 @see ContactMethod
 */
- (void)incrementTimesContacted:(ContactMethod)contactMethod;

@end
