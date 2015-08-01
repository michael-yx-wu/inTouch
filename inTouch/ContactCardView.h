/*!
 @header ContactCardView.h
 
 @brief Contains the ContactCardView class.
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

#import "Contact.h"
#import "MainViewDelegate.h"

/*!
 @class ContactCardView
 
 @brief Handles gestures on the current contact.
 
 @helps MainViewController
        ContactQueueView
 
 @superclass UIView
 */
@interface ContactCardView : UIView


/*!
 @brief A delegate to provide access to some basic contact-related functions in the @link MainViewController @/link.
 */
@property (weak) id <MainViewDelegate> delegate;

/*!
 @group Current Contact
 */
#pragma mark - Current Contact

/*!
 @brief A label for the current @link Contact @/link's name.
 */
@property (weak, nonatomic) IBOutlet UILabel *contactName;

/*!
 @brief The current photo being displayed.
 */
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoFront;

/*!
 @brief A view containing the deleted icon that fades in and out on drag.
 */
@property (weak, nonatomic) IBOutlet UIView *deletedView;

/*!
 @brief A view containing the postponed icon that fades in and out on drag.
 */
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
