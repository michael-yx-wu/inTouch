//
//  GlobalData.h
//  inTouch
//
//  Created by Michael Wu on 5/3/14.
//  Copyright (c) 2014 inTouch Team. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface GlobalData : NSManagedObject

@property (nonatomic, retain) NSNumber * firstRun;
@property (nonatomic, retain) NSDate * lastUpdatedInfo;
@property (nonatomic, retain) NSNumber * numContacts;
@property (nonatomic, retain) NSNumber * numLogins;
@property (nonatomic, retain) NSNumber * numNotInterested;

@end
