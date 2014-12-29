#import "Contact.h"

@protocol MainViewDelegate <NSObject>

- (void)deleteContact;
- (void)performSegueWithIdentifier:(NSString *)string sender:(id)sender;
- (void)dismissContactAndSetReminder:(NSUInteger)days;
- (void)showPickerView;

@end

@interface ContactCardView : UIView

@property (weak) id <MainViewDelegate> delegate;

// Data
@property Contact *contact;

// Data to display
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoFront;
@property (weak, nonatomic) IBOutlet UIView *deletedView;
@property (weak, nonatomic) IBOutlet UIView *postponedView;


// Contact queue photos
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoMiddle;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoBottom;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoAnchor;

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) CGPoint originalPoint;

- (void)setImageCentersAndMasks;
- (void)leftAction;
- (void)rightActionFromButton:(NSInteger)days;
- (void)slideContactCardUp:(NSInteger)days;
- (void)showNameLabel;
- (void)returnToOriginalPositions;
- (void)hideAndDisableInteraction;
- (void)showAndEnableInteraction;

@end
