#import <CoreTelephony/CTCall.h>
#import <AddressBookUI/AddressBookUI.h>

#import "AppDelegate.h"
#import "Contact.h"
#import "ContactInformationTableViewController.h"
#import "ContactManager.h"
#import "NotificationStrings.h"

@interface ContactInformationTableViewController () {
    NSString *nameCellIdentifier,
        *remindSwitchCellIdentifier,
        *phoneCellIdentifier,
        *emailCellIdentifier;
    UISwitch *reminderSwitch;
    NSDictionary *allPhoneNumbers, *allEmailAddresses;
    NSArray *phoneLabels, *emailLabels;
    int nameSection, phoneSection, emailSection;
}

@end

@implementation ContactInformationTableViewController

@synthesize contact;

- (void)viewDidLoad {
    [super viewDidLoad];

    [self loadContactData];
    nameSection = 0;
    phoneSection = [phoneLabels count] > 0 ? 1 : -1;
    emailSection = [emailLabels count] > 0
        ? phoneSection == 1
            ? 2
            : 1
        : -1;

    nameCellIdentifier = @"name";
    remindSwitchCellIdentifier = @"remindSwitch";
    phoneCellIdentifier = @"phone";
    emailCellIdentifier = @"email";
    
    reminderSwitch = [[UISwitch alloc] init];
    [reminderSwitch addTarget:self action:@selector(reminderSwitchFlipped) forControlEvents:UIControlEventValueChanged];
    if ([[(ContactMetadata *)[contact metadata] interest] boolValue]) {
        [reminderSwitch setOn:YES];
    } else {
        [reminderSwitch setOn:NO];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callEnded)
                                                 name:CTCallStateDisconnected
                                               object:nil];
}

- (void)loadContactData {
    allPhoneNumbers = [contact getPhoneNumbers];
    allEmailAddresses = [contact getEmails];
    phoneLabels = [[allPhoneNumbers allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    emailLabels = [[allEmailAddresses allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
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
                                                          [self dismissViewControllerAnimated:YES completion:nil];
                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)callEnded {
    [(ContactMetadata *)[contact metadata] incrementTimesContacted:contactedByCall];
}

- (void)displayMessageViewController:(NSInteger)index {
    MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
    [messageViewController setRecipients:@[[allPhoneNumbers objectForKey:[phoneLabels objectAtIndex:index]]]];
    [messageViewController setMessageComposeDelegate:self];
    [self presentViewController:messageViewController animated:YES completion:nil];
}

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
    if (section == nameSection) {
        // no op
    } else if (section == phoneSection) {
        [self showCallTextActionSheet:row];
    } else if (section == emailSection) {
        [self displayMailViewController:row];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1 + ([phoneLabels count] > 0 ? 1 : 0) + ([emailLabels count] > 0 ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == nameSection) {
        return 2;
    } else if (section == phoneSection) {
        return [phoneLabels count];
    } else if (section == emailSection) {
        return [emailLabels count];
    }

    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == nameSection) {
        return @"";
    } else if (section == phoneSection) {
        return @"Numbers";
    } else if (section == emailSection){
        return @"Emails";
    }

    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if ([indexPath section] == nameSection) {
        if ([indexPath row] == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:nameCellIdentifier forIndexPath:indexPath];
            [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@ %@", [contact nameFirst], [contact nameLast]]];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:remindSwitchCellIdentifier forIndexPath:indexPath];
            [cell setAccessoryView:reminderSwitch];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
    } else if ([indexPath section] == phoneSection) {
        cell = [tableView dequeueReusableCellWithIdentifier:phoneCellIdentifier forIndexPath:indexPath];
        NSString *phoneLabel = [phoneLabels objectAtIndex:[indexPath row]];
        [[cell textLabel] setText:phoneLabel];
        [[cell detailTextLabel] setText:[allPhoneNumbers objectForKey:phoneLabel]];
    } else if ([indexPath section] == emailSection) {
        cell = [tableView dequeueReusableCellWithIdentifier:emailCellIdentifier forIndexPath:indexPath];
        NSString *emailLabel = [emailLabels objectAtIndex:[indexPath row]];
        [[cell textLabel] setText:emailLabel];
        [[cell detailTextLabel] setText:[allEmailAddresses objectForKey:emailLabel]];
    }

    [cell layoutSubviews];
    return cell;
}

- (void)save {
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] saveContext];
}

@end
