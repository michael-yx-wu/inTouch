#import <AddressBookUI/AddressBookUI.h>

#import "AppDelegate.h"
#import "ContactInformationTableViewController.h"
#import "ContactManager.h"

@interface ContactInformationTableViewController () {
    NSInteger newFrequency;
}

@end

@implementation ContactInformationTableViewController

@synthesize nameLabel;
@synthesize phoneHomeLabel;
@synthesize phoneMobileLabel;
@synthesize phoneWorkLabel;
@synthesize emailHomeLabel;
@synthesize emailOtherLabel;
@synthesize emailWorkLabel;
@synthesize interestCell;
@synthesize interestLabel;
@synthesize frequencyLabel;
@synthesize frequencySlider;
@synthesize contact;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get key contact info
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", [contact nameFirst], [contact nameLast]];
    [nameLabel setText:fullName];
    int abrecordid = [[contact abrecordid] intValue];
    
    // Verify contact ID
    abrecordid = [ContactManager verifyABRecordID:abrecordid forContact:contact];
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef currentContact = ABAddressBookGetPersonWithRecordID(addressBookRef, abrecordid);
    
    // Get home, mobile, and work phone numbers
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(currentContact, kABPersonPhoneProperty);
    NSString *phoneLabel, *phoneNumber;
    CFStringRef label;
    for (int j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
        // Get label for current phone number
        label = ABMultiValueCopyLabelAtIndex(phoneNumbers, j);
        phoneLabel = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(label);
        
        if ([phoneLabel isEqualToString:@"home"]) {
            phoneNumber = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            [phoneHomeLabel setText:phoneNumber];
        } else if ([phoneLabel isEqualToString:@"mobile"] || [phoneLabel isEqualToString:@"iPhone"]) {
            phoneNumber = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            [phoneMobileLabel setText:phoneNumber];
        } else if ([phoneLabel isEqualToString:@"work"]) {
            phoneNumber = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            [phoneWorkLabel setText:phoneNumber];
        }
        CFRelease(label);
    }
    
    // Get home, other, and work emails
    ABMultiValueRef emails = ABRecordCopyValue(currentContact, kABPersonEmailProperty);
    NSString *emailLabel, *email;
    for (int j = 0; j < ABMultiValueGetCount(emails); j++) {
        // Get label for current email
        label = ABMultiValueCopyLabelAtIndex(emails, j);
        emailLabel = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(label);
        
        if ([emailLabel isEqualToString:@"home"]) {
            email = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, j);
            [emailHomeLabel setText:email];
        } else if ([emailLabel isEqualToString:@"other"]) {
            email = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, j);
            [emailOtherLabel setText:email];
        } else if ([emailLabel isEqualToString:@"work"]) {
            email = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, j);
            [emailWorkLabel setText:email];
        }
        CFRelease(label);
    }
    
    // Set appropriate value for "interested cell"
    ContactMetadata *contactMetadata = (ContactMetadata *)[contact metadata];
    if ([[contactMetadata interest] intValue]) {
        [interestLabel setText:@"Interested"];
        [interestCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [interestLabel setText:@"Not interested"];
        [interestCell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    // Resize labels to fit
    [nameLabel sizeToFit];
    [phoneHomeLabel sizeToFit];
    [phoneMobileLabel sizeToFit];
    [phoneWorkLabel sizeToFit];
    [emailHomeLabel sizeToFit];
    [emailOtherLabel sizeToFit];
    [emailWorkLabel sizeToFit];
    [interestLabel sizeToFit];
    
    CFRelease(addressBookRef);
    CFRelease(phoneNumbers);
    CFRelease(emails);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)positionFrequencySlider:(NSInteger)freq {
    // Set appropriate value for slider
    // Set frequency slider value and text
    NSString *message;
    if (freq == 1) {
        [frequencySlider setValue:[frequencySlider minimumValue]];
        message = @"Daily";
    }
    else if (freq < 30) {
        [frequencySlider setValue:freq*10];
        message = [NSString stringWithFormat:@"%ld days", (long)freq];
    } else if (freq < 365) {
        [frequencySlider setValue:(freq/30-1)*60+300];
        message = [NSString stringWithFormat:@"%ld months", (long)freq/30];
    } else {
        [frequencySlider setValue:[frequencySlider maximumValue]];
        message = @"Yearly";
    }
    [frequencyLabel setText:message];
}

// Slider to adjust the frequency of desired contact
// Does not save until user hits "save"
- (IBAction)changeFrequency:(id)sender {
    // Map slider value to remind frequency (in days because of eventual CoreData entry)
    NSInteger frequency;
    NSInteger sliderValue = [frequencySlider value];
    if (sliderValue <= 300) {
        frequency = sliderValue/10;
    } else if (sliderValue <= 625) {
        frequency = ((sliderValue-300)/60+1)*30;
    } else {
        frequency = 365;
    }
    newFrequency = frequency;
    
    // Map frequency to user friendly display text
    NSString *message;
    if (frequency == 1) {
        message = @"Daily";
    } else if (frequency <= 30) {
        message = [NSString stringWithFormat:@"Every %ld days", (long)frequency];
    } else if (frequency < 365) {
        NSInteger months = frequency/30;
        message = [NSString stringWithFormat:@"Every %ld months", (long)months];
    } else {
        message = @"Yearly";
    }
    [frequencyLabel setText:message];
}

// Handle cell selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    NSLog(@"%ld", (long)row);
    
    // Frequency section
    if ([indexPath section] == 1) {
        // Interested cell
        if (row == 0) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if ([cell accessoryType] == UITableViewCellAccessoryNone) {
                [interestLabel setText:@"Interested"];
                [interestCell setAccessoryType:UITableViewCellAccessoryCheckmark];
            } else {
                [interestLabel setText:@"Not interested"];
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
        }
    }
    [tableView reloadData];
}

- (IBAction)saveEdits {
    // save contact information -- to be implemented later
    
    // Update interest
    ContactMetadata *metadata = (ContactMetadata *)[contact metadata];
    if ([interestCell accessoryType] == UITableViewCellAccessoryCheckmark) {
        [metadata setInterest:[NSNumber numberWithBool:YES]];
    } else {
        [metadata setInterest:[NSNumber numberWithBool:NO]];
    }
    
    [self save];
    
    // Return to previous screen
    [[self navigationController] popViewControllerAnimated:YES];
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

// Save current context
- (void)save {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate saveContext];
}

@end
