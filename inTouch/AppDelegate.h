/*!
 @header AppDelegate.h
 
 @brief Contains the AppDelegate class.
 
 @author Michael Wu
 @copyright 2015 Intactu
 @version 1.1
 */

/*!
 @class AppDelegate
 
 @brief Responsible for scheduling various tasks on application state changes.
 
 @discussion When the application is launched, 'window' is told the run the main application while 'alertWindow' is
             reserved for Facebook login alerts only. This allows FacebookManager to show alerts regardless of the
             current application state. 'alertWindow' has a clear background color and is normally hidden from view. It
             only becomes visible when FacebookManager displays an alert dialog. After the dialog is dismissed, the view
             is hidden from view once more.
 
             The AppDelegate is also the class that other classes will refer to when they need a save function or a
             pointer to 'managedObjectContext'.
 
 @superclass UIResponder
 
 @see FacebookManager
 */
@interface AppDelegate : UIResponder <UIApplicationDelegate>

/*!
 @brief The UIWindow for the main application.
 */
@property (strong, nonatomic) UIWindow *window;

/*!
 @brief The UIWindow for FacebookManager alerts.
 
 @discussion This is hidden by default. FacebookManager will temporarily make this UIWindow visible while it is 
             presenting an alert.
 */
@property (strong, nonatomic) UIWindow *alertWindow;

/*!
 @brief The application's persistent store coordinator.
 */
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/*!
 @brief The application's managed object model.
 */
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

/*!
 @brief The application's managed object context.
 
 @discussion This is used on the main thread. Other NSManagedObjectContext objects may be used on background threads.
 */
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

/*!
 @brief Save any changes to Core Data entities.
 
 @discussion On save failure, attempts to save at most one more time. If save failure persists, save is aborted.
 */
- (void)saveContext;

@end