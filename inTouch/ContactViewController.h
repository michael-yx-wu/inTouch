//
//  ContactViewController.h
//  inTouch
//
//  Created by Michael Wu on 3/24/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactViewController : UIViewController

// Display
@property (nonatomic, strong) IBOutlet UILabel *contactName;
@property (nonatomic, strong) IBOutlet UIImageView *contactPhoto;
@property (nonatomic, strong) IBOutlet UILabel *lastContactedLabel;

// Contact Data
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) UIImage *photoData;
@property (nonatomic, strong) NSString *lastContactedString;
@property (nonatomic, strong) NSString *emailHome;
@property (nonatomic, strong) NSString *emailWork;
@property (nonatomic, strong) NSString *emailOther;
@property (nonatomic, strong) NSString *phoneHome;
@property (nonatomic, strong) NSString *phoneMobile;
@property (nonatomic, strong) NSString *phoneWork;

@end

static NSString *phoneActionSheetTitle = @"Which number?";
static NSString *emailActionSheetTitle = @"Which email?";
static NSString *contactedCall = @"called";
static NSString *contactedMessage = @"messaged";
static NSString *contactedEmail = @"emailed";
static NSString *contactedGeneric = @"generic";
