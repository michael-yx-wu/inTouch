/*!
 @header DebugLogger.h
 
 @brief Contains the DebugLogger class.
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

/*!
 @class DebugLogger
 
 @brief Used to filter debug output.
*/
@interface DebugLogger : NSObject

/*!
 @brief Attempt to print debug string with the given priority.
 
 @discussion If the global debug level is higher than the priority, output will not print.

 @param message Debug output in the form of a NSString.
 @param priority Priority assigned to the message.
 */
+ (void)log:(NSString*)message withPriority:(NSInteger)priority;

/*!
 @brief Set the global debug level. 
 
 @discussion All debug output with priority lower than the global debug level will fail to print.
 
 @param debugFilter The global debug level will be set to this value.
 */
+ (void)setDebugLevel:(NSInteger)debugFilter;

@end