#import "ContactQueueView.h"

#import "NotificationStrings.h"

@implementation ContactQueueView {
    NSArray *visualElements;
    NSMutableArray *centers;
}

@synthesize delegate;
@synthesize photoAnchor, photoBottom, photoMiddle;
@synthesize contactCard;

- (void)awakeFromNib {
    centers = [[NSMutableArray alloc] initWithCapacity:4];
}

- (void)setImageCenter {
    visualElements = @[photoAnchor, photoBottom, photoMiddle, contactCard];
    for (UIView *view in visualElements) {
        [centers addObject:[NSValue valueWithCGPoint:[view center]]];
    }
}

- (void)dismissQueueLeft {
    [contactCard setUserInteractionEnabled:NO];
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
    [contactCard setUserInteractionEnabled:NO];
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
                         for (int i = 0; i < [visualElements count]; i++) {
                             [[visualElements objectAtIndex:i] setCenter:[[centers objectAtIndex:i] CGPointValue]];
                         }
                     }
                     completion:^(BOOL finished) {
                         if (![delegate queueEmpty]) {
                             [contactCard setUserInteractionEnabled:YES];
                         }
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
                         for (int i = 0; i < [visualElements count]; i++) {
                             [[visualElements objectAtIndex:i] setCenter:[[centers objectAtIndex:i] CGPointValue]];
                         }
                     }
                     completion:^(BOOL finished) {
                         if (![delegate queueEmpty]) {
                             [contactCard setUserInteractionEnabled:YES];
                         }
                         [[NSNotificationCenter defaultCenter] postNotificationName:queueSwitchingDoneNotification
                                                                             object:nil];
                     }];
}

@end
