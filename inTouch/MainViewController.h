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

@end
