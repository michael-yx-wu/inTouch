#import "PickerViewController.h"
enum {
    monthsComponent,
    daysComponent
};

@interface PickerViewController ()
@end

@implementation PickerViewController

@synthesize remindDate;
@synthesize remindDatePickerView;
@synthesize toolbar, cancelButton;
@synthesize daysSinceLastReminder;
@synthesize shouldHideCancelButton;
@synthesize postponingContact;
@synthesize postponingContactFromButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    [remindDatePickerView setDataSource:self];
    [remindDatePickerView setDelegate:self];
    [self configureRows];
    if (shouldHideCancelButton) {
        [self hideCancelButton];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// Determine the correct rows to highlight on load
- (void)configureRows {
    NSUInteger months = daysSinceLastReminder/30;
    NSUInteger days = daysSinceLastReminder%30;
    [remindDatePickerView selectRow:months inComponent:monthsComponent animated:YES];
    [remindDatePickerView selectRow:days inComponent:daysComponent animated:YES];
    [self pickerView:remindDatePickerView didSelectRow:days inComponent:1];
}

- (void)hideCancelButton {
    NSMutableArray *buttons = [[toolbar items] mutableCopy];
    [buttons removeObject:cancelButton];
    [toolbar setItems:buttons animated:NO];
}

#pragma mark - Delegate methods of UIPickerView

// Set the number of scrollable lists in the picker
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

// Set the number of rows in each list
- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == monthsComponent) {
        return 7;
    }
    return 31;
}

// Set the row height -- may need to adjust for larger screens
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 30.0;
}

// Set the text of the rows
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"%ld", row];
}

// Update the remindDate label text
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    // Convert picker rows to days
    NSUInteger months = [pickerView selectedRowInComponent:monthsComponent];
    NSUInteger days = [pickerView selectedRowInComponent:daysComponent];
    NSUInteger totalDays = months * 30 + days;
    
    // Add days to current date and set the label text
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *today = [NSDate date];
    NSDateComponents *futureComponents = [[NSDateComponents alloc] init];
    [futureComponents setDay:totalDays];
    NSDate *remindOnDate = [calendar dateByAddingComponents:futureComponents toDate:today options:0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [remindDate setText:[NSString stringWithFormat:@"Remind me on %@", [dateFormatter stringFromDate:remindOnDate]]];
}

// Cancel
- (IBAction)cancel:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"pickerViewCancel" object:self];
}

// Done
- (IBAction)done:(id)sender {
    NSInteger daysToPostpone = [remindDatePickerView selectedRowInComponent:monthsComponent]*30 +
    [remindDatePickerView selectedRowInComponent:daysComponent];
    NSDictionary *userInfo =  [NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInteger:daysToPostpone],
                                                                    [NSNumber numberWithBool:postponingContact],
                                                                    [NSNumber numberWithBool:postponingContactFromButton]]
                                                          forKeys:@[@"days",
                                                                    @"postponingContact",
                                                                    @"postponingContactFromButton"]];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"pickerViewDone"
                                                        object:self
                                                      userInfo:userInfo];
}

@end
