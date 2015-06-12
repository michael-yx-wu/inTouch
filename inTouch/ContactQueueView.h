#import "ContactCardView.h"
#import "MainViewDelegate.h"

#import "DebugConstants.h"
#import "DebugLogger.h"

@interface ContactQueueView : UIView

@property (weak) id <MainViewDelegate> delegate;

// Elements that need to be animated
@property (weak, nonatomic) IBOutlet UIImageView *photoAnchor;
@property (weak, nonatomic) IBOutlet UIImageView *photoBottom;
@property (weak, nonatomic) IBOutlet UIImageView *photoMiddle;
@property (weak, nonatomic) IBOutlet ContactCardView *contactCard;

//@property (weak, no)

- (void)setImageCenters;
- (void)dismissQueueLeft;
- (void)dismissQueueRight;

@end
