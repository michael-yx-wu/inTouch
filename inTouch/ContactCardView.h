#import "Contact.h"

@protocol MainViewDelegate <NSObject>

- (IBAction)swipeLeftOrTap:(id)sender;
- (IBAction)swipeUpOrTap:(id)sender;

@end

@interface ContactCardView : UIView

@property (weak) id <MainViewDelegate> delegate;

// Data
@property Contact *contact;

// Data to display
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UIImageView *contactPhoto;

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic) CGPoint originalPoint;


@end
