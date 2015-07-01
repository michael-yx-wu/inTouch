@protocol MainViewDelegate <NSObject>

- (void)deleteContact;
- (void)performSegueWithIdentifier:(NSString *)string sender:(id)sender;
- (void)dismissContactAndSetReminder:(NSUInteger)days;
- (void)showPickerView;
- (void)updateQueueWhileOffscreen;

@end