#import "AppDelegate.h"
#import "ContactMetadata.h"
#import "NotificationScheduler.h"


@implementation NotificationScheduler

+ (void)scheduleNotifications {
    NSManagedObjectModel *model = [self managedObjectModel];
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"ContactMetadataAllNonDeleted"
                                                substitutionVariables:[[NSDictionary alloc] init]];

    // Sort by date
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"remindOnDate" ascending:false];
    NSArray *sortDescriptors = @[sortDescriptor];
    [request setSortDescriptors:sortDescriptors];
    
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        NSString *errorString = [NSString stringWithFormat:@"Error fetching contacts while scheduling notifications: %@, %@",
                                 error, [error userInfo]];
        [DebugLogger log:errorString withPriority:notificationSchedulerPriority];
    }
    
    NSMutableDictionary *notificationDates = [[NSMutableDictionary alloc] init];
    NSDate *remindDate, *remindDateAndTime, *today;
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *todaysComponents = [calendar components:(NSCalendarUnitYear|
                                                               NSCalendarUnitMonth|
                                                               NSCalendarUnitDay|
                                                               NSCalendarUnitTimeZone|
                                                               NSCalendarUnitCalendar)
                                                     fromDate:[NSDate date]];
    today = [todaysComponents date];
    
    // Using 10AM as the notification time -- subject to change in future versions
    NSDateComponents *notificationTime = [[NSDateComponents alloc] init];
    [notificationTime setHour:10];
    
    // Sort all contacts into date "buckets"
    for (ContactMetadata *metadata in results) {
        remindDate = [metadata remindOnDate];
        NSComparisonResult dateCompare = [remindDate compare:today];
        
        // Skip over contact if remindOnDate has not been set
        if (!remindDate) {
            continue;
        }
        
        // Determine whether remindOnDate has already passed and increment entries accordingly
        if (dateCompare == NSOrderedAscending || dateCompare == NSOrderedSame) {
            remindDateAndTime = [calendar dateByAddingComponents:notificationTime toDate:today options:0];
        } else {
            remindDateAndTime = [calendar dateByAddingComponents:notificationTime toDate:remindDate options:0];
        }
        [self incrementEntryForDate:remindDateAndTime inDictionary:notificationDates];
    }
    
    NSArray *dates = [notificationDates allKeys];
    dates = [dates sortedArrayUsingSelector:@selector(compare:)];
    NSDate *date;
    NSNumber *contactsForDate;
    UILocalNotification *notification;
    for (int i = 0; i < [dates count]; i++) {
        // Skip notification scheduling for today's scheduled contacts if it is past 10AM
        date = [dates objectAtIndex:i];
        if ([date compare:[NSDate date]] == NSOrderedAscending) {
            continue;
        }
        
        contactsForDate = [notificationDates objectForKey:date];

        // Create the notification
        notification = [[UILocalNotification alloc] init];
        [notification setFireDate:date];
        if (notification == nil) {
            continue;
        }
        
        // Set notification body text based on number of contacts
        [notification setAlertAction:@"View Queue"];
        if ([contactsForDate intValue] == 1) {
            [notification setAlertBody:@"You have 1 new contact in your queue"];
            [notification setAlertTitle:@"inTouch"];
        } else {
            [notification setAlertBody:[NSString stringWithFormat:@"You have %@ new contacts in your queue",
                                        contactsForDate]];
            [notification setAlertTitle:@"New contacts in queue"];
        }
        [notification setSoundName:UILocalNotificationDefaultSoundName];
        [notification setApplicationIconBadgeNumber:1];
        
        // Schedule notification
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    
    // Create a recurring notification to remind people to come back to the app after notifications regarding new
    // contacts in the queue have stopped for 3 days
    if (date) {
        NSDateComponents *recurringNotificationOffset = [[NSDateComponents alloc] init];
        [recurringNotificationOffset setDay:3];
        NSDate *recurringReminder = [calendar dateByAddingComponents:recurringNotificationOffset toDate:date options:0];
        notification = [[UILocalNotification alloc] init];
        [notification setFireDate:recurringReminder];
        [notification setRepeatInterval:NSCalendarUnitWeekOfMonth];
        [notification setAlertAction:@"View Queue"];
        [notification setAlertBody:@"You have contacts in your queue"];
        [notification setAlertTitle:@"inTouch"];
        [notification setSoundName:UILocalNotificationDefaultSoundName];
        [notification setApplicationIconBadgeNumber:1];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

// Helper method to increment the NSNumber value associated with a date in the specified dictionary. Create the entry if
// no such entry exists
+ (void)incrementEntryForDate:(NSDate *)date inDictionary:(NSMutableDictionary *)dict {
    NSNumber *numOnDate = [dict objectForKey:date];
    if (numOnDate) {
        [dict setObject:[NSNumber numberWithInt:([numOnDate intValue]+1)] forKey:date];
    } else {
        [dict setObject:[NSNumber numberWithInt:1] forKey:date];
    }
}

+ (void)dismissNotifications {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

#pragma mark - Core Data Accessor Methods

+ (NSManagedObjectContext *)managedObjectContext {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate managedObjectContext];
}

+ (NSManagedObjectModel *)managedObjectModel {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [appDelegate managedObjectModel];
}

+ (void)save {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate saveContext];
}

@end
