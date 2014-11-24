#import "ContactCardView.h"

#import "DebugLogger.h"
#import "DebugConstants.h"

#define ACTION_MARGIN 120
#define OVERLAY_STRENGTH 0.75
#define ROTATION_ANGLE M_PI/8
#define ROTATION_MAX 1
#define ROTATION_STRENGTH 320
#define SCALE_STRENGTH 4 //%%% how quickly the card shrinks. Higher = slower shrinking
#define SCALE_MAX .93


@implementation ContactCardView {
    CGFloat scaledDistanceToAction;
    CGFloat xFromCenter;
    CGFloat yFromCenter;
    CGPoint originalFrontCenter;
    CGPoint originalMiddleCenter;
    CGPoint originalBottomCenter;
    CGSize originalFrontDimensions;
    CGSize originalMiddleDimensions;
    CGSize originalBottomDimensions;
}

@synthesize contactName;
@synthesize delegate;
@synthesize panGestureRecognizer;
@synthesize tapGestureRecognizer;
@synthesize originalPoint;
@synthesize deletedView;
@synthesize postponedView;

@synthesize contactPhotoFront;
@synthesize contactPhotoMiddle;
@synthesize contactPhotoBottom;
@synthesize contactPhotoAnchor;

- (void)awakeFromNib {
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(beingDragged:)];
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(wasTapped:)];
    [self addGestureRecognizer:panGestureRecognizer];
    [self addGestureRecognizer:tapGestureRecognizer];
    [self resetTranslation];
    originalPoint = CGPointMake([self center].x, [self center].y);
    
    // Save dimensions and centers for contact queue
    originalFrontCenter = [contactPhotoFront center];
    originalMiddleCenter = [contactPhotoMiddle center];
    originalBottomCenter = [contactPhotoBottom center];
    originalFrontDimensions = [contactPhotoFront frame].size;
    originalMiddleDimensions = [contactPhotoMiddle frame].size;
    originalBottomDimensions = [contactPhotoBottom frame].size;
}

// Called when contact card is being dragged. Called many times per second
-(void)beingDragged:(UIPanGestureRecognizer *)gestureRecognizer {
    // Determine where we are dragging the card
    xFromCenter = [gestureRecognizer translationInView:self].x;
    yFromCenter = [gestureRecognizer translationInView:self].y;
    switch ([panGestureRecognizer state]) {
        case UIGestureRecognizerStateBegan: {
            // fade name
            [self hideNameLabel];
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            // No rotation for now
            [self setCenter:CGPointMake(xFromCenter+originalPoint.x, yFromCenter+originalPoint.y)];
            
            // Fade in overlay action
            [self calculateOverlay];
            
            // Move the other middle/bottom cards according to scaledDistanceToAction
            scaledDistanceToAction = ABS(xFromCenter / ACTION_MARGIN);
            scaledDistanceToAction = MIN(1, scaledDistanceToAction);
            [self animateQueueMember:contactPhotoMiddle
                       originalFrame:CGRectMake(originalMiddleCenter.x,
                                                originalMiddleCenter.y,
                                                originalMiddleDimensions.width,
                                                originalMiddleDimensions.height)
                           reference:CGRectMake(originalFrontCenter.x,
                                                originalFrontCenter.y,
                                                originalFrontDimensions.width,
                                                originalFrontDimensions.height)];
            [self animateQueueMember:contactPhotoBottom
                       originalFrame:CGRectMake(originalBottomCenter.x,
                                                originalBottomCenter.y,
                                                originalBottomDimensions.width,
                                                originalBottomDimensions.height)
                           reference:CGRectMake(originalMiddleCenter.x,
                                                originalMiddleCenter.y,
                                                originalMiddleDimensions.width,
                                                originalMiddleDimensions.height)];
            break;
        }
            
        case UIGestureRecognizerStateEnded: {
            [self doneDragging];
            break;
        }
            
        default: {
            break;
        }
    }
}

// Here, originalSize is formatted as follows: (x,y,w,h) where x, y represent the center coordinates and w, h represent
// the width and height.
// reference is formatted as follows: (x,y,w,h) where x, y represent the center coordinates and w, h represent
// the width and height.
- (void)animateQueueMember:(UIImageView *)contactPhoto originalFrame:(CGRect)originalFrame reference:(CGRect)reference {
    // Scale
    CGRect frame = [contactPhoto frame];
    CGFloat width = originalFrame.size.width;
    CGFloat height = originalFrame.size.height;
    width += scaledDistanceToAction*(reference.size.width-width);
    height += scaledDistanceToAction*(reference.size.height-height);
    frame.size.width = width;
    frame.size.height = height;
    [contactPhoto setFrame:frame];
    
    // Translate
    CGFloat newCenterY = originalFrame.origin.y - scaledDistanceToAction*(originalFrame.origin.y - reference.origin.y);
    [contactPhoto setCenter:CGPointMake(originalFrame.origin.x, newCenterY)];
    
    // Redraw circular boundaries
    [[contactPhoto layer] setCornerRadius:contactPhoto.frame.size.width/2];
}

// When delete/postpone buttons clicked, slide up the contact queue photos
- (void)slideUp {
    scaledDistanceToAction = 1;
    [self animateQueueMember:contactPhotoMiddle
               originalFrame:CGRectMake(originalMiddleCenter.x,
                                        originalMiddleCenter.y,
                                        originalMiddleDimensions.width,
                                        originalMiddleDimensions.height)
                   reference:CGRectMake(originalFrontCenter.x,
                                        originalFrontCenter.y,
                                        originalFrontDimensions.width,
                                        originalFrontDimensions.height)];
    [self animateQueueMember:contactPhotoBottom
               originalFrame:CGRectMake(originalBottomCenter.x,
                                        originalBottomCenter.y,
                                        originalBottomDimensions.width,
                                        originalBottomDimensions.height)
                   reference:CGRectMake(originalMiddleCenter.x,
                                        originalMiddleCenter.y,
                                        originalMiddleDimensions.width,
                                        originalMiddleDimensions.height)];
}

// Return the middle and bottom photos to their original positions and sizes
- (void)returnToOriginalPositions {
    // Reset dimensions of middle and bottom photos
    [self setCenter:originalPoint];
    [self setAlpha:1.0];
    CGRect frame = [contactPhotoMiddle frame];
    frame.size = originalMiddleDimensions;
    [contactPhotoMiddle setFrame:frame];
    frame = [contactPhotoBottom frame];
    frame.size = originalBottomDimensions;
    [contactPhotoBottom setFrame:frame];
    [contactPhotoMiddle setCenter:originalMiddleCenter];
    [contactPhotoBottom setCenter:originalBottomCenter];
    [[contactPhotoMiddle layer] setCornerRadius:contactPhotoMiddle.frame.size.width/2];
    [[contactPhotoBottom layer] setCornerRadius:contactPhotoBottom.frame.size.width/2];
}

// Fade name when you start dragging
- (void)hideNameLabel {
    [UIView animateWithDuration:0.15 animations:^{
        [contactName setAlpha:0.0];
    }];
}

// Show name when dragging stops
- (void)showNameLabel {
    [UIView animateWithDuration:0.2 animations:^{
        [contactName setAlpha:1.0];
    }];
}

// Called when done swiping
- (void)doneDragging {
    if (xFromCenter < -ACTION_MARGIN) {
        [self leftAction];
    } else if (xFromCenter > ACTION_MARGIN) {
        [self rightAction];
    } else {
        // Reset the card and overlays
        [UIView animateWithDuration:0.3 animations:^{
            [deletedView setAlpha:0.0];
            [postponedView setAlpha:0.0];
            [self returnToOriginalPositions];
        } completion:^(BOOL finished) {
            [self showNameLabel];
        }];
    }
}

// Move card to left and alert MainViewController to show next contact
- (void)leftAction {
    [UIView animateWithDuration:0.15 animations:^{
        [contactName setAlpha:0.0];
    } completion:^(BOOL finished) {
        CGPoint finishPoint = CGPointMake(-150, 2*yFromCenter + originalPoint.y);
        [UIView animateWithDuration:0.07
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self setCenter:finishPoint];
                             [self slideUp];
                         } completion:^(BOOL finished) {
                             [self setAlpha:1.0];
                             [delegate deleteContact];
                             [self resetTranslation];
                         }];
    }];
}

// Move card to top and alert MainViewController to show next contact
- (void)rightAction {
    [UIView animateWithDuration:0.15 animations:^{
        [contactName setAlpha:0.0];
    } completion:^(BOOL finished) {
        CGPoint finishPoint = CGPointMake(150 + [[UIScreen mainScreen] bounds].size.width, 2*yFromCenter + originalPoint.y);
        [UIView animateWithDuration:0.07
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             [self setCenter:finishPoint];
                             [self slideUp];
                         } completion:^(BOOL finished) {
                             [self setAlpha:1.0];
                             [delegate postponeContact];
                             [self resetTranslation];
                         }];
    }];
}

- (void)calculateOverlay {
    CGFloat relativeDistanceToMargin = fabs(xFromCenter)/ACTION_MARGIN;
    CGFloat alpha = MIN(relativeDistanceToMargin/OVERLAY_STRENGTH, 1.0);
    if (xFromCenter < 0) {                          // Left
        [deletedView setAlpha:alpha];
        [postponedView setAlpha:0];
    } else {                                        // Right
        [deletedView setAlpha:0];
        [postponedView setAlpha:alpha];
    }
}

// Was tapped, tell MainViewController to show the contact buttons
- (void)wasTapped:(UITapGestureRecognizer *)tapGestureRecognizer {
    [DebugLogger log:@"Contact tapped" withPriority:contactCardViewPriority];
    [delegate performSegueWithIdentifier:@"contact" sender:nil];
}

- (void)resetTranslation {
    xFromCenter = 0;
    yFromCenter = 0;
}

- (void)hideAndDisableInteraction {
    [self setUserInteractionEnabled:NO];
    [contactPhotoFront setAlpha:0];
    [contactPhotoMiddle setAlpha:0];
    [contactPhotoBottom setAlpha:0];
    [contactPhotoAnchor setAlpha:0];
}

- (void)showAndEnableInteraction {
    [self setUserInteractionEnabled:YES];
    [contactPhotoFront setAlpha:1];
    [contactPhotoMiddle setAlpha:1];
    [contactPhotoBottom setAlpha:1];
    [contactPhotoAnchor setAlpha:1];
}

@end
