#import <CoreTelephony/CTCall.h>
#import <AddressBookUI/AddressBookUI.h>

#import "AppDelegate.h"
#import "Contact.h"
#import "ContactInformationTableViewController.h"
#import "ContactManager.h"
#import "NotificationStrings.h"
#import "PickerViewController.h"

#define NAME_SECTION 0
#define REMINDERS_SECTION 1
#define REMINDERS_ON_OFF 0
#define REMINDERS_DATE 1
#define PHONES_SECTION 2
#define EMAILS_SECTION 3

@interface ContactInformationTableViewController () {
    NSString *nameCellIdentifier,
        *remindSwitchCellIdentifier,
        *remindDateCellIdentifier,
        *phoneCellIdentifier,
        *emailCellIdentifier;
    NSDictionary *allPhoneNumbers, *allEmailAddresses;
    NSArray *phoneLabels, *emailLabels;
    BOOL hasPhoneSection, hasEmailSection;
    UISwitch *reminderSwitch;
}

@end

@implementation ContactInformationTableViewController

@synthesize contact;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get numbers and emails and determine whether we need to have phone/email sections
    [self loadContactData];
    
    // Set the cell identifiers
    nameCellIdentifier = @"name";
    remindSwitchCellIdentifier = @"remindSwitch";
    remindDateCellIdentifier = @"remindDate";
    phoneCellIdentifier = @"phone";
    emailCellIdentifier = @"email";
    
    reminderSwitch = [[UISwitch alloc] init];
    [reminderSwitch addTarget:self action:@selector(reminderSwitchFlipped) forControlEvents:UIControlEventValueChanged];
    if ([[(ContactMetadata *)[contact metadata] interest] boolValue]) {
        [reminderSwitch setOn:YES];
    } else {
        [reminderSwitch setOn:NO];
    }
    
    // Listen for reminder switch changess
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateRemindDateCell)
                                                 name:pickerViewDoneFromSettingsNotification
                                               object:nil];
    
    // Listen for call end events
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callEnded)
                                                 name:CTCallStateDisconnected
                                               object:nil];
}

- (void)loadContactData {
    // Get phones and emails from contact and sort the labels into nsarrays
    allPhoneNumbers = [contact getPhoneNumbers];
    allEmailAddresses = [contact getEmails];
    phoneLabels = [[allPhoneNumbers allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    emailLabels = [[allEmailAddresses allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    hasPhoneSection = [phoneLabels count] != 0 ? YES : NO;
    hasEmailSection = [emailLabels count] != 0 ? YES : NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Reminders

- (void)reminderSwitchFlipped {
    ContactMetadata *contactMetadata = (ContactMetadata *)[contact metadata];
    if ([reminderSwitch isOn]) {
        [contactMetadata setInterest:[NSNumber numberWithBool:YES
                                      ]];
    } else {
        [contactMetadata setInterest:[NSNumber numberWithBool:NO]];
    }
    [self save];
    [self updateRemindDateCell];
}

- (void)showReminderDatePicker {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PickerViewController *pvc = [storyboard instantiateViewControllerWithIdentifier:@"picker"];
    [pvc setShouldHideCancelButton:NO];
    [pvc setPostponingContact:NO];
    [pvc setPostponingContactFromButton:NO];
    [pvc setDisplayedInMainView:NO];
    [pvc setContact:contact];
    
    [[self navigationController] setProvidesPresentationContextTransitionStyle:YES];
    [[self navigationController] setDefinesPresentationContext:YES];
    [pvc setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [[self navigationController] presentViewController:pvc animated:YES completion:nil];
}

// Refresh the remind date cell's detail text
- (void)updateRemindDateCell {
    [[self tableView] beginUpdates];
    [[self tableView] reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:REMINDERS_DATE inSection:REMINDERS_SECTION]]
                            withRowAnimation:UITableViewRowAnimationAutomatic];
    [[self tableView] endUpdates];
}

#pragma mark - Contacting

// Here, index is the row selected in the phones section of the table
- (void)showCallTextActionSheet:(NSInteger)index {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Call or Message?"
                                                                             message:@""
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Call"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          NSString *number = [allPhoneNumbers objectForKey:[phoneLabels objectAtIndex:index]];
                                                          number = [number stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                                          number = [NSString stringWithFormat:@"telprompt:%@", number];
                                                          NSURL *phoneURL = [NSURL URLWithString:number];
                                                          [[UIApplication sharedApplication] openURL:phoneURL];
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Message"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          [self displayMessageViewController:index];
                                                      }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
//                                                          [self dismissViewControllerAnimated:YES completion:nil];
                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

// Executed upon receiving a call ended notification
- (void)callEnded {
    [(ContactMetadata *)[contact metadata] incrementTimesContacted:contactedByCall];
}

- (void)displayMessageViewController:(NSInteger)index {
    MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
    [messageViewController setRecipients:@[[allPhoneNumbers objectForKey:[phoneLabels objectAtIndex:index]]]];
    [messageViewController setMessageComposeDelegate:self];
    [self presentViewController:messageViewController animated:YES completion:nil];
}

// Handle message controller being dismissed
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:^{
        switch (result) {
            case MessageComposeResultCancelled: {
                [DebugLogger log:@"Message cancelled" withPriority:contactInformationTableViewControllerPriority];
                break;
            }
            case MessageComposeResultFailed: {
                [DebugLogger log:@"Message failed" withPriority:contactInformationTableViewControllerPriority];
                break;
            }
            case MessageComposeResultSent: {
                [DebugLogger log:@"Message sent" withPriority:contactInformationTableViewControllerPriority];
                [(ContactMetadata *)[contact metadata] incrementTimesContacted:contactedByMessage];
            }
            default: {
                break;
            }
        }
    }];
}

- (void)displayMailViewController:(NSInteger)index {
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    [mailViewController setToRecipients:@[[allEmailAddresses objectForKey:[emailLabels objectAtIndex:index]]]];
    [mailViewController setMailComposeDelegate:self];
    [self presentViewController:mailViewController animated:YES completion:nil];
}


// Handle email controller being dismissed
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:^{
        switch (result) {
            case MFMailComposeResultCancelled: {
                [DebugLogger log:@"Mail cancelled" withPriority:contactInformationTableViewControllerPriority];
                break;
            }
            case MFMailComposeResultFailed: {
                [DebugLogger log:@"Mail compose failed" withPriority:contactInformationTableViewControllerPriority];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                         message:@"Message compose failed"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
                break;
            }
            case MFMailComposeResultSaved: {
                [DebugLogger log:@"Mail saved" withPriority:contactInformationTableViewControllerPriority];
                break;
            }
            case MFMailComposeResultSent: {
                [DebugLogger log:@"Mail sent" withPriority:contactInformationTableViewControllerPriority];
                [(ContactMetadata *)[contact metadata] incrementTimesContacted:contactedByEmail];
                break;
            }
            default: {
                break;
            }
        }
    }];
}

#pragma mark - Tableview delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO];

    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];    
    if (section == NAME_SECTION) {
        // no op
    } else if (section == REMINDERS_SECTION && row == REMINDERS_DATE) {
        [self showReminderDatePicker];
        return;
    } else if (section >= 2) {
        if (hasPhoneSection) {
            if (section == PHONES_SECTION) {
                [self showCallTextActionSheet:row];
            } else if (section == EMAILS_SECTION) {
                [self displayMailViewController:row];
            }
        } else {
            [self displayMailViewController:row];
        }
    }
}

// Dynamically set the number of sections to be displayed
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 2;
    if (hasPhoneSection) {
        numberOfSections += 1;
    }
    if (hasEmailSection) {
        numberOfSections += 1;
    }
    return numberOfSections;
}

// Name and Reminders section have constant row counts. Phone and Email sections may or may not exist and have variable
// row counts.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == NAME_SECTION) {
        return 1;
    } else if (section == REMINDERS_SECTION) {
        return 2;
    } else {
        if (hasPhoneSection) {
            if (section == PHONES_SECTION) {
                return [phoneLabels count];
            } else if (section == EMAILS_SECTION) {
                return [emailLabels count];
            }
        } else {
            return [emailLabels count];
        }
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == NAME_SECTION) {
        return @"";
    }
    else if (section == REMINDERS_SECTION) {
        return @"Reminders";
    }
    else if (hasPhoneSection) {
        if (section == PHONES_SECTION) {
            return @"Numbers";
        } else if (section == EMAILS_SECTION) {
            return @"Emails";
        }
    } else {
        return @"";
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    // Determine which section we are looking at
    if ([indexPath section] == NAME_SECTION) {
        cell = [tableView dequeueReusableCellWithIdentifier:nameCellIdentifier forIndexPath:indexPath];
        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@ %@", [contact nameFirst], [contact nameLast]]];
    } else if ([indexPath section] == REMINDERS_SECTION) {
        ContactMetadata *contactMetadata = (ContactMetadata *)[contact metadata];
        if ([indexPath row] == REMINDERS_ON_OFF) {
            cell = [tableView dequeueReusableCellWithIdentifier:remindSwitchCellIdentifier forIndexPath:indexPath];
            [cell setAccessoryView:reminderSwitch];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        if ([indexPath row] == REMINDERS_DATE) {
            cell = [tableView dequeueReusableCellWithIdentifier:remindDateCellIdentifier forIndexPath:indexPath];
            // Set enabled status
            if ([[contactMetadata interest] boolValue]) {
                cell.userInteractionEnabled = cell.textLabel.enabled = cell.detailTextLabel.enabled = YES;
            } else {
                cell.userInteractionEnabled = cell.textLabel.enabled = cell.detailTextLabel.enabled = NO;
            }
            
            // Set the text
            NSDate *remindDate = [contactMetadata remindOnDate];
            if (remindDate) {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
                [[cell detailTextLabel] setText:[dateFormatter stringFromDate:remindDate]];
            } else {
                [[cell detailTextLabel] setText:@"Not set"];
            }
        }
    } else if (hasPhoneSection) {
        if ([indexPath section] == PHONES_SECTION) {
            cell = [tableView dequeueReusableCellWithIdentifier:phoneCellIdentifier forIndexPath:indexPath];
            NSString *phoneLabel = [phoneLabels objectAtIndex:[indexPath row]];
            [[cell textLabel] setText:phoneLabel];
            NSLog(@"%@", phoneLabel);
            [[cell detailTextLabel] setText:[allPhoneNumbers objectForKey:phoneLabel]];
        }
        if ([indexPath section] == EMAILS_SECTION) {
            cell = [tableView dequeueReusableCellWithIdentifier:emailCellIdentifier forIndexPath:indexPath];
            NSString *emailLabel = [emailLabels objectAtIndex:[indexPath row]];
            [[cell textLabel] setText:emailLabel];
            [[cell detailTextLabel] setText:[allEmailAddresses objectForKey:emailLabel]];
        }
    } else {
        if (hasEmailSection) {
            cell = [tableView dequeueReusableCellWithIdentifier:emailCellIdentifier forIndexPath:indexPath];
            NSString *emailLabel = [emailLabels objectAtIndex:[indexPath row]];
            [[cell textLabel] setText:emailLabel];
            [[cell detailTextLabel] setText:[allEmailAddresses objectForKey:emailLabel]];
        }
    }
    
    // Configure the cell...
    [cell layoutSubviews];
    return cell;
}


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

- (void)save {
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] saveContext];
}

@end
