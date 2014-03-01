//
//  DebugLogger.h
//  inTouch
//
//  Created by Michael Wu on 2/28/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DebugLogger : NSObject

+ (void)log:(NSString*)message withPriority:(NSInteger)priority;
+ (void)setDebugLevel:(NSInteger)debugLevel;

@end