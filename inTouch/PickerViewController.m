#import "AppDelegate.h"
#import "NotificationStrings.h"
#import "PickerViewController.h"

#define NAME_PREFERRED_FONT_SIZE 22
#define NAME_MAX_WIDTH 200
#define PICKER_ROW_HEIGHT 25

enum {
    staticComponent,
    daysWeeksComponent,
    daysWeeksToggleComponent
};

@interface PickerViewController () {
    BOOL daysSelected;
}
@end

@implementation PickerViewController

@synthesize contact, contactPhotoView, contactNameLabel;
@synthesize remindDateHelpText;
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
    daysSelected = true;
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
}

- (void)hideCancelButton {
    NSMutableArray *buttons = [[toolbar items] mutableCopy];
    [buttons removeObject:cancelButton];
    [toolbar setItems:buttons animated:NO];
}

// Display different help text depending on the action associated with the picker
- (void)setRemindHelpText {
    if (postponingContact) {
        [remindDateHelpText setText:@"Postpone for:"];
    } else {
        [remindDateHelpText setText:@"Remind me in:"];
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

#pragma mark - Delegate methods of UIPickerView

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == staticComponent) {
        return 1;
    } else if (component == daysWeeksComponent) {
        return 10;
    } else {
        return 2;
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return PICKER_ROW_HEIGHT;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return [[self view] bounds].size.width/3;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                              0,
                                                              [self pickerView:pickerView widthForComponent:component],
                                                              PICKER_ROW_HEIGHT)];
    [label setNumberOfLines:1];
    [label setAdjustsFontSizeToFitWidth:YES];
    [label setFont:[UIFont systemFontOfSize:20]];
    [label setTextAlignment:NSTextAlignmentCenter];
    if (component == staticComponent) {
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setFont:[UIFont systemFontOfSize:16]];
        if (postponingContact || postponingContactFromButton) {
            [label setText:@"Postpone for"];
        } else {
            [label setText:@"Remind me in"];
        }
    } else if (component == daysWeeksComponent) {
        [label setText:[NSString stringWithFormat:@"%ld", (long)(row + 1)]];
    } else {
        if (row == 0) {
            [label setText:@"days"];
        } else {
            [label setText:@"weeks"];
        }
    }

    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == daysWeeksToggleComponent) {
        if (row == 0) {
            daysSelected = true;
        } else {
            daysSelected = false;
        }
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
        NSInteger daysUntilReminder;
        if (daysSelected) {
            daysUntilReminder = [remindDatePickerView selectedRowInComponent:daysWeeksComponent] + 1;
        } else {
            daysUntilReminder = ([remindDatePickerView selectedRowInComponent:daysWeeksComponent] + 1) * 7;
        }

        if (displayedInMainView) {
            NSDictionary *userInfo =  [NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInteger:daysUntilReminder],
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
            [(ContactMetadata *)[contact metadata] setRemindOnDate:[self calculateRemindDateFromSelection:daysUntilReminder]];
            AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
            [delegate saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:pickerViewDoneFromSettingsNotification
                                                                object:self];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (NSDate *)calculateRemindDateFromSelection:(NSInteger)days {
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *todaysComponents = [calendar components:(NSCalendarUnitYear|
                                                               NSCalendarUnitMonth|
                                                               NSCalendarUnitDay|
                                                               NSCalendarUnitTimeZone|
                                                               NSCalendarUnitCalendar)
                                                     fromDate:[NSDate date]];
    NSDate *today = [todaysComponents date];
    NSDateComponents *futureComponents = [[NSDateComponents alloc] init];
    [futureComponents setDay:days];
    return [calendar dateByAddingComponents:futureComponents toDate:today options:0];
}

@end
