//
//  Contact.h
//  inTouch
//
//  Created by Michael Wu on 3/17/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

@interface Contact : NSManagedObject

@property (nonatomic, retain) NSNumber *category;
@property (nonatomic, retain) NSData *contactPhoto;
@property (nonatomic, retain) NSString *emailHome;
@property (nonatomic, retain) NSString *emailOther;
@property (nonatomic, retain) NSString *emailWork;
@property (nonatomic, retain) NSNumber *identity;
@property (nonatomic, retain) NSString *nameFirst;
@property (nonatomic, retain) NSString *nameLast;
@property (nonatomic, retain) NSString *phoneHome;
@property (nonatomic, retain) NSString *phoneMobile;
@property (nonatomic, retain) NSString *phoneWork;

@end

