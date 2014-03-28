//
//  ViewController.h
//  inTouch
//
//  Created by Michael Wu on 2/28/14.
//  Copyright (c) 2014 Michael Wu. All rights reserved.
//

@interface MainViewController : UIViewController

// Display the name of the current contact
@property (weak, nonatomic) IBOutlet UILabel *displayName;
// Display the frequency as user uses the slider
@property (weak, nonatomic) IBOutlet UILabel *viewFrequency;
// Display the contact picture
@property (weak, nonatomic) IBOutlet UIImageView *contactPicture;



@end
