/*
 The purpose of this class is to compartmentalize the urgency formula.
 Make all edits to the formula in the implementation file of this class.
 Urgency formula edits need only occur once for edits to be applied across
 the board.
 */

@interface UrgencyCalculator : NSObject

+ (void)updateAll;
+ (void)updateUrgencyContact:(NSManagedObject *)contact Metadata:(NSManagedObject *)metadata;

@end


