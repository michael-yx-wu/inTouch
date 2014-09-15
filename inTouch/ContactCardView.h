#import "Contact.h"

@protocol MainViewDelegate <NSObject>

- (IBAction)swipeLeftOrTap:(id)sender;
- (IBAction)swipeRightOrTap:(id)sender;
- (IBAction)contactTap:(id)sender;

@end

@interface ContactCardView : UIView

@property (weak) id <MainViewDelegate> delegate;

// Data
@property Contact *contact;

// Data to display
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhoto;
@property (weak, nonatomic) IBOutlet UIView *deletedView;
@property (weak, nonatomic) IBOutlet UIView *postponedView;

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) CGPoint originalPoint;

- (void) leftAction;
- (void) rightAction;

@end
