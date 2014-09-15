#import "ContactCardView.h"

#define ACTION_MARGIN 120
#define OVERLAY_STRENGTH 0.75
#define ROTATION_ANGLE M_PI/8
#define ROTATION_MAX 1
#define ROTATION_STRENGTH 320
#define SCALE_STRENGTH 4 //%%% how quickly the card shrinks. Higher = slower shrinking
#define SCALE_MAX .93


@implementation ContactCardView {
    CGFloat xFromCenter;
    CGFloat yFromCenter;
}

@synthesize delegate;
@synthesize panGestureRecognizer;
@synthesize tapGestureRecognizer;
@synthesize originalPoint;
@synthesize deletedView;
@synthesize postponedView;

- (void)awakeFromNib {
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(beingDragged:)];
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(wasTapped:)];
    [self addGestureRecognizer:panGestureRecognizer];
    [self addGestureRecognizer:tapGestureRecognizer];
    [self resetTranslation];
    originalPoint = [self center];
}

// Called when contact card is being dragged. Called many times per second
-(void)beingDragged:(UIPanGestureRecognizer *)gestureRecognizer {
    // Determine where we are dragging the card
    xFromCenter = [gestureRecognizer translationInView:self].x;
    yFromCenter = [gestureRecognizer translationInView:self].y;
    switch ([panGestureRecognizer state]) {
        case UIGestureRecognizerStateBegan: {
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            // No rotation for now
            [self setCenter:CGPointMake(xFromCenter+originalPoint.x, yFromCenter+originalPoint.y)];
            
            // Fade in overlay action
            [self calculateOverlay];
            
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
            [self setCenter:originalPoint];
            [self setTransform:CGAffineTransformMakeRotation(0)];
        }];
    }
}

// Move card to left and alert MainViewController to show next contact
- (void)leftAction {
    CGPoint finishPoint = CGPointMake(-75, 2*yFromCenter + originalPoint.y);
    [UIView animateWithDuration:0.07
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self setCenter:finishPoint];
                     } completion:^(BOOL finished) {
                         [self setAlpha:0];
                         [delegate deleteContact];
                         [self resetTranslation];
                     }];
}

// Move card to top and alert MainViewController to show next contact
- (void)rightAction {
    CGPoint finishPoint = CGPointMake(75 + [[UIScreen mainScreen] bounds].size.width, 2*yFromCenter + originalPoint.y);
    [UIView animateWithDuration:0.07
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self setCenter:finishPoint];
                     } completion:^(BOOL finished) {
                         [self setAlpha:0];
                         [delegate postponeContact];
                         [self resetTranslation];
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
    [delegate contactTap:nil];
}

- (void)resetTranslation {
    xFromCenter = 0;
    yFromCenter = 0;
}

@end
