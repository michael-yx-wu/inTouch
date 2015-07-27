/*!
 @header DebugConstants.h
 
 @brief Macros for debug priority constants.
 
 @discussion Each file is assigned as an integer representing its debug priority. Higher numbers represent higher 
             priority. Edit the contents of this file in conjunction with DebugLogger to change the debug output 
             content.
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

#define minimumPriorityThreshold 1
#define appDelegatePriority 1
#define contactManagerPriority 2
#define urgencyCalculatorPriority 2
#define mainViewControllerPriority 3
#define contactViewControllerPriority 3
#define helpViewControllerPriority 1
#define settingsTableViewControllerPriority 1
#define allContactsTableViewControllerPriority 2
#define contactInformationTableViewControllerPriority 2
#define contactCardViewPriority 3
#define facebookManagerPriority 3
#define rootViewControllerPriority 3
#define loginViewControllerPriority 3
#define notificationSchedulerPriority 3