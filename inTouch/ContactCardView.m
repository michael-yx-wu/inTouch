#import "ContactCardView.h"

#define ACTION_MARGIN 120
#define OVERLAY_STRENGTH 0.75

@implementation ContactCardView {
    CGFloat xFromCenter;
    CGFloat yFromCenter;
}

@synthesize delegate;
@synthesize panGestureRecognizer;
@synthesize originalPoint;
@synthesize deletedView;
@synthesize postponedView;

- (void)awakeFromNib {
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(beingDragged:)];
    [self addGestureRecognizer:panGestureRecognizer];
}

// Called when contact card is being dragged. Called many times per second
-(void)beingDragged:(UIPanGestureRecognizer *)gestureRecognizer {
    // Determine where we are dragging the card
    NSLog(@"Being dragged");
    xFromCenter = [gestureRecognizer translationInView:self].x;
    yFromCenter = [gestureRecognizer translationInView:self].y;
    NSLog(@"%f %f", xFromCenter, yFromCenter);
    switch ([panGestureRecognizer state]) {
        case UIGestureRecognizerStateBegan: {
            originalPoint = [self center];
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            // No rotation for now
            [self setCenter:CGPointMake(self.originalPoint.x + xFromCenter, self.originalPoint.y + yFromCenter)];
            //            CGFloat rotationStrength = MIN(fabs(xFromCenter) / ROTATION_STRENGTH, ROTATION_MAX);
            //            if (xFromCenter < 0) {
            //                rotationStrength *= -1;
            //            }
            //            CGFloat rotationAngle = (CGFloat) (ROTATION_ANGLE * rotationStrength);
            //            CGAffineTransform transform = CGAffineTransformMakeRotation(1);
            //            self.transform = transform;
            
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
    if (xFromCenter <- ACTION_MARGIN) {
        [self leftAction];
    } else if (yFromCenter < -ACTION_MARGIN) {
        [self upAction];
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
    CGPoint finishPoint = CGPointMake(-200, 2*yFromCenter + originalPoint.y);
    [UIView animateWithDuration:0.1 animations:^{
        [self setCenter:finishPoint];
    } completion:^(BOOL finished) {
        [delegate swipeLeftOrTap:nil];
    }];
}

// Move card to top and alert MainViewController to show next contact
- (void)upAction {
    CGPoint finishPoint = CGPointMake(2*xFromCenter + originalPoint.x, -200);
    [UIView animateWithDuration:0.1 animations:^{
        [self setCenter:finishPoint];
    } completion:^(BOOL finished) {
        [delegate swipeUpOrTap:nil];
    }];
}

- (void)calculateOverlay {
    CGFloat distanceFromCenter;
    if (fabs(xFromCenter) > fabs(yFromCenter)) {        // Left/right
        if (xFromCenter < 0) {                          // Left
            distanceFromCenter = -xFromCenter;
        } else {                                        // Right
            distanceFromCenter = xFromCenter;
        }
        CGFloat relativeDistanceToMargin = fabs(distanceFromCenter)/ACTION_MARGIN;
        CGFloat alpha = MIN(relativeDistanceToMargin/OVERLAY_STRENGTH, 1.0);
        [deletedView setAlpha:alpha];
        [postponedView setAlpha:0];
    } else {                                            // Up
        distanceFromCenter = -yFromCenter;
        CGFloat relativeDistanceToMargin = fabs(distanceFromCenter)/ACTION_MARGIN;
        CGFloat alpha = MIN(relativeDistanceToMargin/OVERLAY_STRENGTH, 1.0);
        [postponedView setAlpha:alpha];
        [deletedView setAlpha:0];
    }
}


@end
