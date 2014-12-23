#import "PickerViewController.h"
enum {
    weeksComponent,
    daysComponent
};

@interface PickerViewController ()
@end

@implementation PickerViewController

@synthesize remindDate;
@synthesize remindDatePickerView;
@synthesize toolbar, cancelButton;
@synthesize daysBetweenReminder;
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
    NSUInteger weeks = daysBetweenReminder/7;
    NSUInteger days = daysBetweenReminder%7;
    [remindDatePickerView selectRow:weeks inComponent:weeksComponent animated:YES];
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
    if (component == weeksComponent) {
        return 7;
    }
    return 31;
}

// Set the row height -- may need to adjust for larger screens
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 24.0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return [[self view] bounds].size.width/3;
}

-(NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    if (component == weeksComponent) {
        [paragraphStyle setAlignment:NSTextAlignmentRight];
    } else {
        [paragraphStyle setAlignment:NSTextAlignmentLeft];
    }
    return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)row]
                                           attributes:@{NSParagraphStyleAttributeName:paragraphStyle}];
}

// Update the remindDate label text
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    // Convert picker rows to days
    NSUInteger weeks = [pickerView selectedRowInComponent:weeksComponent];
    NSUInteger days = [pickerView selectedRowInComponent:daysComponent];
    NSUInteger totalDays = weeks * 7 + days;
    
    // Add days to current date and set the label text
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate *today = [NSDate date];
    NSDateComponents *futureComponents = [[NSDateComponents alloc] init];
    [futureComponents setDay:totalDays];
    NSDate *remindOnDate = [calendar dateByAddingComponents:futureComponents toDate:today options:0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    if (totalDays == 0) {
        [remindDate setText:@" later today"];
    } else {
            [remindDate setText:[NSString stringWithFormat:@" %@", [dateFormatter stringFromDate:remindOnDate]]];
    }
}

// Cancel
- (IBAction)cancel:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"pickerViewCancel" object:self];
}

// Done
- (IBAction)done:(id)sender {
    NSInteger daysToPostpone = [remindDatePickerView selectedRowInComponent:weeksComponent]*30 +
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
