/*!
 @header GlobalData.h
 
 @brief Contains the subclass for the GlobalData entity in Core Data. 
 
 @discussion The subclass below makes it easier to interact with the GlobalData entity in Core Data.
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

/*!
 @class GlobalData
 
 @brief Subclass for the GlobalData entity in Core Data.
 
 @discussion This subclass makes it easier to interact with the GlobalData entity in Core Data.
 
 @superclass NSManagedObject
 */
@interface GlobalData : NSManagedObject

/*!
 @brief A string used to login on app launch after a successful first login.
 
 @warning Currently not being used because inTouch API logins have been disabled.
 */
@property (nonatomic, retain) NSString *accessToken;

/*! 
 @brief A boolean to remember whether it is the first time tapping contacts.
 
 @discussion Used to show a popup teaching new users how to use the app.
 
 @warning Not yet implemented in the tutorial.
 */
@property (nonatomic, retain) NSNumber *firstContactTap;

/*!
 @brief A boolean to remember whether it is the first time left swiping contacts.
 
 @discussion Used to show a popup teaching new users how to use the app.
 
 @warning Not yet implemented in the tutorial.
 */

@property (nonatomic, retain) NSNumber *firstLeftSwipe;

/*!
 @brief A boolean to remember whether it is the first time switching queues.
 
 @discussion Used to show a popup teaching new users how to use the app.
 
 @warning Not yet implemented in the tutorial.
 */
@property (nonatomic, retain) NSNumber *firstQueueSwitch;

/*!
 @brief A boolean to remember whether it is the first time right swiping contacts.
 
 @discussion Used to show a popup teaching new users how to use the app.
 
 @warning Not yet implemented in the tutorial.
 */
@property (nonatomic, retain) NSNumber *firstRightSwipe;

/*!
 @brief A boolean to remember whether it is the first time running the app.
 
 @discussion Used to show the TutorialViewController to new users.
 */
@property (nonatomic, retain) NSNumber *firstRun;

/*!
 @brief The date on which contacts were last synced with the system address book.
 */
@property (nonatomic, retain) NSDate *lastUpdatedInfo;

/*!
 @brief The total number of contacts.
 */
@property (nonatomic, retain) NSNumber *numContacts;

/*!
 @brief The total number of logins.
 */
@property (nonatomic, retain) NSNumber *numLogins;

/*!
 @brief The total number of contacts that are marked with 'not interested'.
 */
@property (nonatomic, retain) NSNumber *numNotInterested;

@end
