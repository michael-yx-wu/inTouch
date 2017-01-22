/*!
 @header MainViewDelegate.h
 
 @brief Contains the MainViewDelegate protocol.
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

/*!
 @protocol MainViewDelegate
 
 @brief Provides access to some basic contact-related functions in the MainViewController.
 
 @helps ContactCardView
        ContactQueueView
 
 @see MainViewController
 */
@protocol MainViewDelegate <NSObject>

/*!
 @brief Dismiss the current @link Contact @/link and set interest to NO.
 
 @discussion This method will also cause the queue to be updated and redrawn, so there is no need to manually do it.
 */
- (void)deleteContact;

/*!
 @brief Allows the @link ContactCardView @/link to let the @link MainViewController @/link know that the current contact
        was tapped. 
 */
- (void)performSegueWithIdentifier:(NSString *)string sender:(id)sender;

/*!
 @brief Dismiss contact from queue and decrement weight.
 */
- (void)dismissContactAndDecrementWeight;

/*!
 @brief Redraw the contact queue while it is animating offscreen. 
 */
- (void)updateQueueWhileOffscreen;

/*!
 @brief Manually call the checkContactButton method.
 
 @discussion Allows classes that use the MainViewDelegate to mimic the check button being tapped.
 */
- (IBAction)checkContactButton:(id)sender;

/*!
 @brief Check if the current queue is empty. 
 
 @return Returns YES if queue is empty. Returns NO otherwise.
 */
- (BOOL)queueEmpty;

@end
