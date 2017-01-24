#import "AppDelegate.h"
#import "ContactMetadata.h"
#import "NotificationScheduler.h"


@implementation NotificationScheduler

+ (void)scheduleNotifications {
    NSManagedObjectModel *model = [self managedObjectModel];
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"ContactMetadataAllNonDeleted"
                                                substitutionVariables:[[NSDictionary alloc] init]];

    NSManagedObjectContext *moc = [self managedObjectContext];
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        NSString *errorString = [NSString stringWithFormat:@"Error fetching contacts while scheduling notifications: %@, %@",
                                 error, [error userInfo]];
        [DebugLogger log:errorString withPriority:notificationSchedulerPriority];
    }

    if ([results count] > 0) {
        NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        NSDateComponents *recurringNotificationOffset = [[NSDateComponents alloc] init];
        [recurringNotificationOffset setDay:7];
        NSDate *notificationDate = [calendar dateByAddingComponents:recurringNotificationOffset toDate:[NSDate date] options:0];
        notification = [[UILocalNotification alloc] init];
        [notification setFireDate:notificationDate];
        [notification setRepeatInterval:NSCalendarUnitWeekOfMonth];
        [notification setAlertAction:@"View Queue"];
        [notification setAlertBody:@"Stay in touch with the people you care about"];
        [notification setAlertTitle:@"inTouch"];
        [notification setSoundName:UILocalNotificationDefaultSoundName];
        [notification setApplicationIconBadgeNumber:1];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

+ (void)dismissNotifications {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

#pragma mark - Core Data Accessor Methods

+ (NSManagedObjectContext *)managedObjectContext {
    return [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
}

+ (NSManagedObjectModel *)managedObjectModel {
    return [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectModel];
}

+ (void) save {
    return [(AppDelegate *)[[UIApplication sharedApplication] delegate] saveContext];
}

@end
