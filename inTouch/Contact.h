//
//  Contact.h
//  inTouch
//
//  Created by Michael Wu on 5/3/14.
//  Copyright (c) 2014 inTouch Team. All rights reserved.
//

@interface Contact : NSManagedObject

@property (nonatomic, retain) NSNumber * abrecordid;
@property (nonatomic, retain) NSNumber * category;
@property (nonatomic, retain) NSData * facebookPhoto;
@property (nonatomic, retain) NSData * linkedinPhoto;
@property (nonatomic, retain) NSString * nameFirst;
@property (nonatomic, retain) NSString * nameLast;
@property (nonatomic, retain) NSManagedObject *metadata;

@end
