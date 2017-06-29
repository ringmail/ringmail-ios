//
//  RgContactManager.m
//  ringmail
//
//  Created by Mike Frager on 12/3/15.
//
//

#import <UIKit/UIKit.h>
#import <NSHash/NSString+NSHash.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MessageUI.h>
#import "RgNetwork.h"
#import "RgContactManager.h"
#import "RgManager.h"
#import "DTActionSheet.h"
#import "PhoneMainView.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberUtil.h"
#import "RKContactStore.h"

@implementation RgContactManager

#pragma mark - Lifecycle Functions

- (id)init {
    self = [super init];
    if (self) {
        contacts = nil;
        dateFormatter = [[NSDateFormatter alloc] init];
        enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    }
    return self;
}

#pragma mark - Manage Contact Syncing

- (NSArray*)getContactList
{
    return [self getContactList:NO];
}

- (NSArray*)getContactList:(BOOL)reload
{
    if (reload || contacts == nil)
    {
		contacts = [[[LinphoneManager instance] fastAddressBook] getContactsArray];
    }
    return contacts;
}

- (NSDictionary *)getAddressBookStats:(NSArray*)contactList
{
	FastAddressBook *fab = [[LinphoneManager instance] fastAddressBook];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSString *lastMod = nil;
    NSDate *maxDate = nil;
    int counter = 0;
    for (id person in contacts)
    {
        counter++;
        NSDate *modDate = [fab getModDate:(__bridge ABRecordRef)person];
        if (maxDate)
        {
            if ([(NSDate*)maxDate compare:modDate] == NSOrderedAscending)
            {
                maxDate = modDate;
            }
        }
        else
        {
            maxDate = modDate;
        }
    }
    //NSLog(@"Max Date: %@", maxDate);
    if (maxDate)
    {
        [result setObject:maxDate forKey:@"date_update"];
        lastMod = [dateFormatter stringFromDate:maxDate];
        //NSLog(@"Last Mod: %@", lastMod);
    }
    if (lastMod == nil)
    {
        lastMod = @"";
    }
    [result setObject:lastMod forKey:@"ts_update"];
    NSNumber *count = [NSNumber numberWithInt:counter];
    [result setObject:count forKey:@"count"];
    return result;
}

- (NSMutableArray *)getContactData:(NSArray*)contactList
{
    NSMutableArray *contactsArray = [NSMutableArray array];
    FastAddressBook *fab = [[LinphoneManager instance] fastAddressBook];
    for (id lPerson in contactList)
    {
        [contactsArray addObject:[fab contactItem:(__bridge ABRecordRef)lPerson]];
    }
    return contactsArray;
}

- (void)inviteToRingMail:(ABRecordRef)contact
{
    DTActionSheet *sheet = [[DTActionSheet alloc] initWithTitle:NSLocalizedString(@"Invite To RingMail", nil)];

    if ([MFMailComposeViewController canSendMail])
    {
        ABMultiValueRef emailMap = ABRecordCopyValue((ABRecordRef)contact, kABPersonEmailProperty);
        if (emailMap)
        {
            for(int i = 0; i < ABMultiValueGetCount(emailMap); ++i)
            {
                NSString* val = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emailMap, i));
                if (val)
                {
                    [sheet addButtonWithTitle:val block:^() {
                        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
                        mail.mailComposeDelegate = self;
                        [mail setSubject:@"You're Invited To RingMail"];
                        [mail setMessageBody:@"You are invited to explore RingMail. Make free calls/text now. https://ringmail.com/dl" isHTML:NO];
                        [mail setToRecipients:@[val]];
                        [[PhoneMainView instance] presentViewController:mail animated:YES completion:NULL];
                    }];
                }
            }
            CFRelease(emailMap);
        }
    }
    if([MFMessageComposeViewController canSendText])
    {
        ABMultiValueRef phoneMap = ABRecordCopyValue((ABRecordRef)contact, kABPersonPhoneProperty);
        NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
        if (phoneMap) {
            for(int i = 0; i < ABMultiValueGetCount(phoneMap); ++i) {
                __block NSString* val = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneMap, i));
                if (val)
                {
                    NSError *anError = nil;
                    NBPhoneNumber *myNumber = [phoneUtil parse:val defaultRegion:@"US" error:&anError];
                    if (anError == nil && [phoneUtil isValidNumber:myNumber])
                    {
                        val = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&anError];
                        [sheet addButtonWithTitle:val block:^() {
                            MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
                            controller.body = @"You are invited to explore RingMail. Make free calls/text now. https://ringmail.com/dl";
                            controller.recipients = @[val];
                            controller.messageComposeDelegate = self;
                            [[PhoneMainView instance] presentModalViewController:controller animated:YES];
                        }];
                    }
                }
            }
            CFRelease(phoneMap);
        }
    }

    [sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:^{}];
    [sheet showInView:[PhoneMainView instance].view];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [[PhoneMainView instance] dismissModalViewControllerAnimated:YES];
    if (result == MessageComposeResultCancelled)
    {
        NSLog(@"Message cancelled");
    }
    else if (result == MessageComposeResultSent)
    {
        NSLog(@"Message sent");
    }
    else
    {
        NSLog(@"Message failed");
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultSent:
            NSLog(@"You sent the email.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"You saved a draft of this email");
            break;
        case MFMailComposeResultCancelled:
            NSLog(@"You cancelled sending this email.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed:  An error occurred when trying to compose this email");
            break;
        default:
            NSLog(@"An error occurred when trying to compose this email");
            break;
    }
    
    [[PhoneMainView instance] dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark Remote API calls

- (void)sendContactData
{
    NSArray *contactList = [self getContactList];
    [self sendContactData:contactList];
}

- (void)sendContactData:(NSArray*)contactList
{
    NSArray *ctd = [self getContactData:contactList];
    //NSLog(@"RingMail: Send Contact Data: %@", ctd);
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:ctd options:0 error:nil];
    NSString *ctdjson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [[RgNetwork instance] updateContacts:@{@"contacts": ctdjson} callback:^(NSURLSessionTask *operation, id responseObject) {
        NSDictionary* res = responseObject;
        NSString *ok = [res objectForKey:@"result"];
        if ([ok isEqualToString:@"ok"])
        {
            NSArray *rgMatches = [res objectForKey:@"rg_matches"];
            if (rgMatches)
            {
                //NSLog(@"RingMail: Updated Matches: %@", rgMatches);
                [[RKContactStore sharedInstance] updateMatches:rgMatches];
            }
            NSArray *rgContacts = [res objectForKey:@"rg_contacts"];
            if (rgContacts)
            {
                //NSLog(@"RingMail: Updated Contacts: %@", rgContacts);
                [[RKContactStore sharedInstance] updateDetails:rgContacts];
                [[NSNotificationCenter defaultCenter] postNotificationName:kRgContactsUpdated object:self userInfo:@{}];
            }
        }
        else if ([ok isEqualToString:@"Unauthorized"])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kRgUserUnauthorized object:nil userInfo:nil];
        }
        else
        {
            NSLog(@"RingMail API Error: %@", @"Update contacts failed");
        }
    }];
}

@end
