/*!
 @header NotificationScheduler.h
 
 @brief Contains the NotificationScheduler class
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

#import "DebugLogger.h"

/*!
 @class NotificationScheduler
 
 @brief Schedules local notifications to remind users when new contacts appear in the 'seen queue'. 
 
 @discussion All scheduled local notifications are dismissed whenever the application resumes being in the active state.
             When the application is about to resign active, the AppDelegate class schedules local notifications. This
             approach is consistent. Local notifications should never report an incorrect number of new contacts.
 
 @superclass NSObject

 @see AppDelegate
 */
@interface NotificationScheduler : NSObject

/*!
 @brief Schedule local notifications for all contacts that have a non-nil remind date.
 
 @discussion When a notification is fired, the badge number is set to 1. Subsequent notifications will not cause this
             number to change.
 */
+ (void)scheduleNotifications;

/*!
 @brief Dismiss all scheduled local notifications and remove the application badge number.
 */
+ (void)dismissNotifications;

@end
