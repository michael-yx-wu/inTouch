#import "AppDelegate.h"
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

@synthesize contact, contactPhotoView, contactNameLabel;
@synthesize remindDateHelpText;
@synthesize remindDate;
@synthesize remindDatePickerView;
@synthesize toolbar, cancelButton;
@synthesize shouldHideCancelButton;
@synthesize postponingContact;
@synthesize postponingContactFromButton;
@synthesize displayedInMainView;

#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    [remindDatePickerView setDataSource:self];
    [remindDatePickerView setDelegate:self];
    [contactNameLabel setAdjustsFontSizeToFitWidth:YES];
    [self setRemindHelpText];
    if (shouldHideCancelButton) {
        [self hideCancelButton];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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
    [super viewWillAppear:animated];
    
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", [contact nameFirst], [contact nameLast]];
    [contactNameLabel setText:fullName];
    [contactPhotoView setImage:[UIImage imageWithData:[contact getPhotoData]]];
    
    // Set weeks/days right before appearing to allow time to set the displayedInMainView variable
    [self configureRows];
}

// Determine the correct rows to highlight on load
- (void)configureRows {
    NSUInteger weeks = 0;
    NSUInteger days = 0;
    
    // Different behavior when not being displayed after contacting or postponing
    if (!displayedInMainView) {
        // Attempt to set picker date to correct number of weeks and days to match the current remind date
        NSDate *oldRemindDate = [(ContactMetadata *)[contact metadata] remindOnDate];
        if (oldRemindDate) {
            NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
            NSDateComponents *todaysComponents = [calendar components:(NSCalendarUnitYear|
                                                                       NSCalendarUnitMonth|
                                                                       NSCalendarUnitDay|
                                                                       NSCalendarUnitTimeZone|
                                                                       NSCalendarUnitCalendar)
                                                             fromDate:[NSDate date]];
            NSDate *today = [todaysComponents date];
            NSDateComponents *diff = [calendar components:NSDayCalendarUnit fromDate:today toDate:oldRemindDate options:0];
            
            // If remind date is already past, default to 0 weeks, 0 days
            if ([diff day] >= 0) {
                weeks = [diff day]/7;
                days = [diff day]%7;
            }
        }
    } else {
        NSInteger daysBetweenReminder = [[(ContactMetadata *)[contact metadata] daysBetweenReminder] integerValue];
        weeks = daysBetweenReminder/7;
        days = daysBetweenReminder%7;
    }
    
    // Scroll to components to correct rows
    [remindDatePickerView selectRow:weeks inComponent:weeksComponent animated:NO];
    [remindDatePickerView selectRow:days inComponent:daysComponent animated:NO];
    
    // Force an update of remindDateLabel
    [self pickerView:remindDatePickerView didSelectRow:days inComponent:daysComponent];
}

- (void)hideCancelButton {
    NSMutableArray *buttons = [[toolbar items] mutableCopy];
    [buttons removeObject:cancelButton];
    [toolbar setItems:buttons animated:NO];
}

// Display different help text depending on the action associated with the picker
- (void)setRemindHelpText {
    if (displayedInMainView) {
        if (postponingContact) {
            [remindDateHelpText setText:@"Postpone until:"];
        } else {
            [remindDateHelpText setText:@"Remind me on:"];
        }
    } else {
        [remindDateHelpText setText:@"Set reminder for:"];
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

#pragma mark - Setting the remind text

// Update the remindDate label text
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    // Get the remind date
    NSInteger totalDays = [self convertSelectionToDays];
    NSDate *remindOnDate = [self calculateRemindDateFromSelection:totalDays];
    [self setRemindText:remindOnDate daysFromNow:totalDays];
}

- (NSInteger)convertSelectionToDays {
    // Convert picker rows to days
    NSInteger weeks = [remindDatePickerView selectedRowInComponent:weeksComponent];
    NSInteger days = [remindDatePickerView selectedRowInComponent:daysComponent];
    return weeks * 7 + days;
}

- (NSDate *)calculateRemindDateFromSelection:(NSInteger)totalDays {
    // Add days to current date and set the label text
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *todaysComponents = [calendar components:(NSCalendarUnitYear|
                                                               NSCalendarUnitMonth|
                                                               NSCalendarUnitDay|
                                                               NSCalendarUnitTimeZone|
                                                               NSCalendarUnitCalendar)
                                                     fromDate:[NSDate date]];
    NSDate *today = [todaysComponents date];
    NSDateComponents *futureComponents = [[NSDateComponents alloc] init];
    [futureComponents setDay:totalDays];
    return [calendar dateByAddingComponents:futureComponents toDate:today options:0];
}

- (void)setRemindText:(NSDate*)date daysFromNow:(NSInteger)daysFromNow {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    if (daysFromNow == 0) {
        [remindDate setText:@" later today"];
    } else {
        [remindDate setText:[NSString stringWithFormat:@" %@", [dateFormatter stringFromDate:date]]];
    }
}


#pragma mark - Dismissing the view

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
        if (displayedInMainView) {
            // Send notification to main view controller to dismiss and begin custom animations
            [[NSNotificationCenter defaultCenter] postNotificationName:pickerViewCancelNotification object:self];
        } else {
            // In the settings menu, we can safely dismiss within this view controller
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (IBAction)done:(id)sender {
    [self fadeOutWithAction:^{
        if (displayedInMainView) {
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
        } else {
            // In the settings menu, we have to set the reminder and dismiss within this view controller
            NSInteger daysFromNow = [self convertSelectionToDays];
            [(ContactMetadata *)[contact metadata] setRemindOnDate:[self calculateRemindDateFromSelection:daysFromNow]];
            AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
            [delegate saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:pickerViewDoneFromSettingsNotification
                                                                object:self];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

@end
