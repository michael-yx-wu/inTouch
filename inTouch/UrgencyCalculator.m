/*
 The purpose of this class is to compartmentalize the urgency formula.
 Make all edits to the formula in the implementation file of this class.
 Urgency formula edits need only occur once for edits to be applied across
 the board.
 */

#include <stdlib.h>

#import "AppDelegate.h"
#import "Contact.h"
#import "ContactMetadata.h"
#import "UrgencyCalculator.h"

#import "DebugConstants.h"
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
                          error, [error userInfo]] withPriority:urgencyCalculatorPriority];
        abort();
    }
    
    [DebugLogger log:[NSString stringWithFormat:@"Updating urgency for %lu contacts",
                      (unsigned long)[results count]] withPriority:urgencyCalculatorPriority];

    ContactMetadata *metadata;
    Contact *contact;
    for (int i = 0; i < [results count]; i++) {
        metadata = [results objectAtIndex:i];
        contact = (Contact *)[metadata contact];
        [self updateUrgencyContact:contact];
    }
}

// Update the urgency for the contact
+ (void)updateUrgencyContact:(Contact *)contact {
    NSNumber *urgency;
    
    // Calculate the urgency using the contact's metadata
    ContactMetadata *metadata = (ContactMetadata *)[contact metadata];
    double numTimesContacted = [[metadata numTimesContacted] doubleValue];
    double numTimesPostponed = [[metadata numTimesPostponed] doubleValue];
    double frequency = [[metadata freq] doubleValue];
    NSDate *lastContactedDate = [metadata lastContactedDate];
    
    double numTimesAppeared = numTimesContacted + numTimesPostponed;
    NSDate *currentDate = [NSDate date];
    double daysSinceLastContact;
    if (lastContactedDate) {
        NSDateComponents *diff = [[NSCalendar currentCalendar] components:NSCalendarUnitDay
                                                                fromDate:lastContactedDate
                                                                  toDate:currentDate
                                                                 options:0];
        daysSinceLastContact = [diff day];
        urgency = [NSNumber numberWithFloat:(numTimesContacted/numTimesAppeared)*daysSinceLastContact/frequency];
    } else {
        // Never contacted before
        // urgency = 1 + random value - small amount per times postponed
        double randValue = 1+(((double)arc4random()/UINT_MAX)*0.05)-0.001*numTimesPostponed;
        urgency = [NSNumber numberWithBool:randValue];
    }

    // Save the new urgency value
    [metadata setUrgency:urgency];
    [DebugLogger log:[NSString stringWithFormat:@"New urgency for %@ %@: %f",
                      [contact nameFirst], [contact nameLast], [urgency doubleValue]]
        withPriority:urgencyCalculatorPriority];
    [self save];
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

