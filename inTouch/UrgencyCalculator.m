//
//  UrgencyCalculator.m
//  inTouch
//
//  Created by Michael Wu on 4/14/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

/*
 The purpose of this class is to compartmentalize the urgency formula.
 Make all edits to the formula in the implementation file of this class.
 Urgency formula edits need only occur once for edits to be applied across
 the board.
 */

#include <stdlib.h>

#import "AppDelegate.h"
#import "UrgencyCalculator.h"

#import "DebugLogger.h"

@implementation UrgencyCalculator

+ (void)updateAll {    
    // Set up request
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    NSDictionary *placeholder = @{};
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"ContactMetadataAllNonDeleted"
                                                substitutionVariables:placeholder];
    
    // Get all ContactMetadata entities
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil){
        [DebugLogger log:[NSString stringWithFormat:@"Urgency update error: %@, %@",
                          error, [error userInfo]] withPriority:1];
        abort();
    }
    
    [DebugLogger log:[NSString stringWithFormat:@"Updating urgency for %lu contacts",
                      (unsigned long)[results count]] withPriority:1];

    NSManagedObject *metadata;
    NSDate *currentDate = [NSDate date];
    NSDate *lastContactedDate;
    NSNumber *freq;
    NSNumber *urgency;
    for (int i = 0; i < [results count]; i++) {
        metadata = [results objectAtIndex:i];
        lastContactedDate = [metadata valueForKey:@"lastContactedDate"];
        freq = [metadata valueForKey:@"freq"];
        urgency = [self calculateUrgencyCurrentDate:currentDate lastContactedDate:lastContactedDate frequency:freq];
        [metadata setValue:urgency forKey:@"urgency"];
    }
    [self save];
}

+ (void)updateUrgencyFirstName:(NSString *)firstName lastName:(NSString *)lastName {
    NSArray *results = [self fetchContact:firstName lastName:lastName];
    NSManagedObject *contact = [results objectAtIndex:0];
    NSManagedObject *metadata = [contact valueForKey:@"metadata"];
    
    NSDate *currentDate = [NSDate date];
    NSDate *lastContactedDate = [metadata valueForKey:@"lastContactedDate"];
    NSNumber *freq = [metadata valueForKey:@"freq"];
    
    // Update urgency based on frequencies and last date contacted
    // For now, urg = (currentdate - lastdate)/freq or 0 if
    // the expression < 1
    NSNumber *urgency = [self calculateUrgencyCurrentDate:currentDate lastContactedDate:lastContactedDate frequency:freq];
    
    // Save the new urgency value
    [metadata setValue:urgency forKey:@"urgency"];
    [DebugLogger log:[NSString stringWithFormat:@"New urgency for %@ %@: %f", firstName, lastName, [urgency doubleValue]] withPriority:1];
    [self save];
}

// Get the Contact entity from core data
+ (NSArray *)fetchContact:(NSString *)firstName lastName:(NSString *)lastName {
    [DebugLogger log:[NSString stringWithFormat:@"Updating urgency for %@ %@", firstName, lastName] withPriority:1];
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSManagedObjectModel *model = [self managedObjectModel];
    
    // ContactNameMatch - return all contacts that match first name AND last name fields
    NSDictionary *subVars = @{
                              @"NAMEFIRST": firstName,
                              @"NAMELAST": lastName
                              };
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"ContactNameMatch" substitutionVariables:subVars];
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    if (results == nil) {
        [DebugLogger log:[NSString stringWithFormat:@"Fetch error: %@, %@",
                          error, [error userInfo]] withPriority:5];
        abort();
    }
    if ([results count] != 1) {
        [DebugLogger log:[NSString stringWithFormat:@"Abort! Multiple contacts with same name: %@ %@", firstName, lastName] withPriority:5];
    }
    return results;
}

+ (NSNumber *)calculateUrgencyCurrentDate:(NSDate *)currentDate lastContactedDate:(NSDate *)lastContactedDate frequency:(NSNumber *)freq {
    // Update urgency based on frequencies and last date contacted
    // For now, urg = (currentdate - lastdate)/freq or 0 if
    // the expression < 1
    NSNumber *urgency;
    NSDateComponents *diff;
    double daysSinceLastContact;
    
    // If never contacted, default urgency is 1
    if (lastContactedDate == nil) {
        double  randValue = ((double)arc4random()/UINT_MAX)*0.05+1;
        urgency = [NSNumber numberWithDouble:randValue];
    }
    // Calculate urg using formula above
    else {
        diff = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:lastContactedDate toDate:currentDate options:0];
        daysSinceLastContact = [diff day];
        urgency = [NSNumber numberWithDouble:daysSinceLastContact/[freq doubleValue]];
        if ([urgency doubleValue] < 1) {
            urgency = [NSNumber numberWithDouble:0];
        }
    }
    return urgency;
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

