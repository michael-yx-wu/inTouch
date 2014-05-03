#import <Foundation/Foundation.h>

@interface DebugLogger : NSObject

+ (void)log:(NSString*)message withPriority:(NSInteger)priority;
+ (void)setDebugLevel:(NSInteger)debugLevel;

@end