#import "NotificationStrings.h"
#import "PickerViewController.h"

#define NAME_PREFERRED_FONT_SIZE 22
#define NAME_MAX_WIDTH 200
#define PICKER_ROW_HEIGHT 25

enum {
    weeksComponent,
    daysComponent
};

@interface PickerViewController ()
@end

@implementation PickerViewController

@synthesize contact, contactPhoto, contactPhotoView, contactNameLabel;
@synthesize remindDateHelpText;
@synthesize remindDate;
@synthesize remindDatePickerView;
@synthesize toolbar, cancelButton;
@synthesize daysBetweenReminder;
@synthesize shouldHideCancelButton;
@synthesize postponingContact;
@synthesize postponingContactFromButton;

#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    [remindDatePickerView setDataSource:self];
    [remindDatePickerView setDelegate:self];
    [contactNameLabel setAdjustsFontSizeToFitWidth:YES];
    [self setRemindHelpText];
    [self configureRows];
    if (shouldHideCancelButton) {
        [self hideCancelButton];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    // Give the appearance of a modal-like dialog
    [UIView animateWithDuration:0.30 animations:^{
       [[self view] setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]];
    }];
}

// Resize and reposition after laying out subviews to get correct frame width. Data is filled in the viewWillAppear
// method to prevent autolayout from interfering with frame updating
- (void)viewDidLayoutSubviews {
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", [contact nameFirst], [contact nameLast]];
    [self centerNameAndPhoto:fullName];
}

- (void)viewWillAppear:(BOOL)animated {
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", [contact nameFirst], [contact nameLast]];
    [contactNameLabel setText:fullName];
    [contactPhotoView setImage:contactPhoto];
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

// Display different help text depending on the action associated with the picker
- (void)setRemindHelpText {
    if (postponingContact) {
        [remindDateHelpText setText:@"Postpone until:"];
    } else {
        [remindDateHelpText setText:@"Remind me on:"];
    }
}

#pragma mark - Name and photo positioning

// Adjust width of name label to fit text up to a maximum specified width
- (void)centerNameAndPhoto:(NSString *)name {
    // Calculate frames of name label and photo view
    CGSize size = [name sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:NAME_PREFERRED_FONT_SIZE]}];
    CGFloat newWidth = MIN(NAME_MAX_WIDTH, ceilf(size.width));
    CGFloat mid = CGRectGetMidX([[self view] frame]);
    CGRect currentContactNameLabelFrame = [contactNameLabel frame];
    CGRect newContactNameLabelFrame = CGRectMake(mid - newWidth/2,
                                                 CGRectGetMinY(currentContactNameLabelFrame),
                                                 newWidth,
                                                 CGRectGetHeight(currentContactNameLabelFrame));
    CGRect currentPhotoFrame = [contactPhotoView frame];
    CGRect newContactPhotoFrame = CGRectMake(CGRectGetMinX(newContactNameLabelFrame) - CGRectGetWidth(currentPhotoFrame) - 8,
                                             CGRectGetMinY(currentPhotoFrame),
                                             CGRectGetWidth(currentPhotoFrame),
                                             CGRectGetHeight(currentPhotoFrame));

    
    [contactNameLabel setFrame:newContactNameLabelFrame];
    [contactPhotoView setFrame:newContactPhotoFrame];
    
    // Reset to preferred font size
    [contactNameLabel setFont:[UIFont systemFontOfSize:NAME_PREFERRED_FONT_SIZE]];
}

// Move the photo
- (void)adjustPhotoPosition {
    CGRect newContactNameLabelFrame = [contactNameLabel frame];
    CGRect currentPhotoFrame = [contactPhotoView frame];
    CGRect newContactPhotoFrame = CGRectMake(CGRectGetMinX(newContactNameLabelFrame) - CGRectGetWidth(currentPhotoFrame) - 8,
                                             CGRectGetMinY(currentPhotoFrame),
                                             CGRectGetWidth(currentPhotoFrame),
                                             CGRectGetHeight(currentPhotoFrame));

    [contactPhotoView setFrame:newContactPhotoFrame];
}

#pragma mark - Delegate methods of UIPickerView

// Set the number of scrollable lists in the picker
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

// Set the number of rows in each list
- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 7;
}

// Set the row height -- may need to adjust for larger screens
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return PICKER_ROW_HEIGHT;
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

- (void)fadeOutWithAction:(void (^)(void))actionBlock {
    [UIView animateWithDuration:0.30
                     animations:^{
                         [[self view] setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0]];
                     }
                     completion:^(BOOL finished) {
                         actionBlock();
                     }];
}

- (IBAction)cancel:(id)sender {
    // Fade out the background before sending the cancel notification
    [self fadeOutWithAction:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:pickerViewCancelNotification object:self];
    }];
}

- (IBAction)done:(id)sender {
    [self fadeOutWithAction:^{
        NSInteger daysToPostpone = [remindDatePickerView selectedRowInComponent:weeksComponent]*30 +
        [remindDatePickerView selectedRowInComponent:daysComponent];
        NSDictionary *userInfo =  [NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInteger:daysToPostpone],
                                                                        [NSNumber numberWithBool:postponingContact],
                                                                        [NSNumber numberWithBool:postponingContactFromButton]]
                                                              forKeys:@[@"days",
                                                                        @"postponingContact",
                                                                        @"postponingContactFromButton"]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:pickerViewDoneNotification
                                                            object:self
                                                          userInfo:userInfo];
    }];
}

@end
