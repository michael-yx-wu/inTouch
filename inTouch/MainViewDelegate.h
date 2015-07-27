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
 @brief Dismiss the current @link Contact @/link and set a reminder.
 
 @discussion This method will also cause the queue to be updated and redrawn, so there is no need to manually do it.
 
 @param days 
    Set a reminder this many days from now.
 */
- (void)dismissContactAndSetReminder:(NSUInteger)days;

/*!
 @brief Show the @link PickerViewController @/link.
 */
- (void)showPickerView;

/*!
 @brief Redraw the contact queue while it is animating offscreen. 
 */
- (void)updateQueueWhileOffscreen;

@end