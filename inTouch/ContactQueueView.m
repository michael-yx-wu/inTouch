#import "ContactQueueView.h"

#import "NotificationStrings.h"

@implementation ContactQueueView {
    NSArray *visualElements;
    NSMutableArray *visualElementCenters;
}

@synthesize delegate;
@synthesize photoAnchor, photoBottom, photoMiddle;
@synthesize contactCard;

- (void)awakeFromNib {
    visualElements = @[photoAnchor, photoBottom, photoMiddle, contactCard];
}

- (void)setImageCenters {
    for (UIView *view in visualElements) {
        [visualElementCenters addObject:[NSValue valueWithCGPoint:[view center]]];
    }
}

- (void)dismissQueueLeft {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         for (UIView *view in visualElements) {
                             [view setCenter:CGPointMake(-[view frame].size.width/2, [view center].y)];
                         }
                     } completion:^(BOOL finished) {
                         [delegate updateQueueWhileOffscreen];
                         [self enterQueueRight];
                     }];
}

- (void)dismissQueueRight {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         for (UIView *view in visualElements) {
                             [view setCenter:CGPointMake([[UIScreen mainScreen] bounds].size.width+[view frame].size.width/2,
                                                         [view center].y)];
                         }
                     } completion:^(BOOL finished) {
                         [delegate updateQueueWhileOffscreen];
                         [self enterQueueLeft];
                     }];
}

- (void)enterQueueLeft {
    for (UIView *view in visualElements) {
        [view setCenter:CGPointMake(-[view frame].size.width/2, [view center].y)];
    }
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         for (UIView *view in visualElements) {
                             [view setCenter:CGPointMake([[UIScreen mainScreen] bounds].size.width/2, [view center].y)];
                         }
                     }
                     completion:^(BOOL finished) {
                         [[NSNotificationCenter defaultCenter] postNotificationName:queueSwitchingDoneNotification
                                                                             object:nil];
                     }];
}

- (void)enterQueueRight {
    for (UIView *view in visualElements) {
        [view setCenter:CGPointMake([[UIScreen mainScreen] bounds].size.width+[view frame].size.width/2,
                                    [view center].y)];
    }
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         for (UIView *view in visualElements) {
                             [view setCenter:CGPointMake([[UIScreen mainScreen] bounds].size.width/2, [view center].y)];
                         }
                     }
                     completion:^(BOOL finished) {
                         [[NSNotificationCenter defaultCenter] postNotificationName:queueSwitchingDoneNotification
                                                                             object:nil];
                     }];
}

@end
