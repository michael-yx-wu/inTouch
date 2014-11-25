#import "Contact.h"

@protocol MainViewDelegate <NSObject>

- (IBAction)deleteContact;
- (IBAction)postponeContact;
- (void)performSegueWithIdentifier:(NSString *)string sender:(id)sender;
- (void)dismissContactAndSetReminder:(NSUInteger)days;

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

- (void)leftAction;
- (void)rightAction;
- (void)slideContactCardUp:(NSUInteger)days;
- (void)showNameLabel;
- (void)returnToOriginalPositions;
- (void)hideAndDisableInteraction;
- (void)showAndEnableInteraction;

@end
