#import "DebugLogger.h"

@implementation DebugLogger

static NSInteger debugLevel;

// Prints message to stdout if priority greater than the minimum required 
// priority. Otherwise message is ignored.
+ (void)log:(NSString*)message withPriority:(NSInteger)priority {
    if (priority >= debugLevel) {
        NSLog(@"%@", message);
    }
}

+ (void)setDebugLevel:(NSInteger)debugFilter {
    debugLevel = debugFilter;
}

@end
