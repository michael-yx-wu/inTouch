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
@property (weak, nonatomic) IBOutlet UILabel *lastContactedLabel;

// User interaction
@property (weak, nonatomic) IBOutlet UIView *contactedView; 
@property (weak, nonatomic) IBOutlet UIView *deletedView;
@property (weak, nonatomic) IBOutlet UIView *postponedView;

// Current contact remind frequency
@property (weak, nonatomic) IBOutlet UISlider *frequencySlider;
@property (weak, nonatomic) IBOutlet UILabel *viewFrequency;

// Current contact attributes in core data
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSData *photoData;
@property int abrecordid;
@property (strong, nonatomic) NSString *emailHome;
@property (strong, nonatomic) NSString *emailOther;
@property (strong, nonatomic) NSString *emailWork;
@property (strong, nonatomic) NSString *phoneHome;
@property (strong, nonatomic) NSString *phoneMobile;
@property (strong, nonatomic) NSString *phoneWork;
@property (strong, nonatomic) NSDate *lastContactedDate;

@end
