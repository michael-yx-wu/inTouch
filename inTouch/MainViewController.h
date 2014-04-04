//
//  ViewController.h
//  inTouch
//
//  Created by Michael Wu on 2/28/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

@interface MainViewController : UIViewController

// Current contact name and photo
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhoto;

// Current contact remind frequency
@property (weak, nonatomic) IBOutlet UILabel *viewFrequency;

@property (weak, nonatomic) NSString *firstName;
@property (weak, nonatomic) NSString *lastName;
@property (weak, nonatomic) NSData *contactPhotoData;
@property (weak, nonatomic) NSString *emailHome;
@property (weak, nonatomic) NSString *emailOther;
@property (weak, nonatomic) NSString *emailWork;
@property (weak, nonatomic) NSString *phoneHome;
@property (weak, nonatomic) NSString *phoneMobile;
@property (weak, nonatomic) NSString *phoneWork;

@end
