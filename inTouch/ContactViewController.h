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
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UIImageView *photoView;

// Contact Data
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, strong) NSString *emailHome;
@property (nonatomic, strong) NSString *emailWork;
@property (nonatomic, strong) NSString *emailOther;
@property (nonatomic, strong) NSString *phoneHome;
@property (nonatomic, strong) NSString *phoneMobile;
@property (nonatomic, strong) NSString *phoneWork;

@end
