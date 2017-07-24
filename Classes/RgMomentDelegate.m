//
//  RgMomentDelegate.m
//  ringmail
//
//  Created by Mike Frager on 5/25/17.
//
//

#import "RgMomentDelegate.h"
#import "PhoneMainView.h"
#import "ImageCountdownViewController.h"
#import "LNNotificationsUI.h"

@implementation RgMomentDelegate

@synthesize file;

+ (instancetype)sharedInstance
{
    static RgMomentDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedInstance = [[RgMomentDelegate alloc] init];
    });
    return sharedInstance;
}

- (void)didSelectMultipleContacts:(NSMutableArray*)contacts
{
	NSLog(@"%s: Contacts: %@\nFile: %@", __PRETTY_FUNCTION__, contacts, file);
	NSData* imgData = [NSData dataWithContentsOfFile:file];
	RKCommunicator* comm = [RKCommunicator sharedInstance];
	for (NSString* recipient in contacts)
	{
    	RKAddress* address = [RKAddress newWithString:recipient];
    	RKThread* thread = [comm getThreadByAddress:address];
		RKMomentMessage* pmsg = [RKMomentMessage newWithData:@{
			@"thread": thread,
			@"direction": [NSNumber numberWithInteger:RKItemDirectionOutbound],
			@"body": @"Moment",
			@"deliveryStatus": @(RKMessageStatusSending),
			@"mediaData": imgData,
			@"mediaType": @"image/png",
		}];
		[comm sendMessage:pmsg];
	}
	[[NSFileManager defaultManager] removeItemAtPath:file error:NULL];
	[[PhoneMainView instance] changeCurrentView:[RgMainViewController compositeViewDescription] push:NO];
	NSInteger ct = [contacts count];
	NSString* s = @"s";
	if (ct == 1)
	{
		s = @"";
	}
	NSString* msg = [NSString stringWithFormat:@"Sent Moment To %ld Contact%@", ct, s];
	LNNotification* notification = [LNNotification notificationWithMessage:msg];
	/*notification.defaultAction = [LNNotificationAction actionWithTitle:@"Default Action" handler:^(LNNotificationAction *action) {
		//Handle default action
		//NSLog(@"%s: Default action", __PRETTY_FUNCTION__);
	}];*/
	[[LNNotificationCenter defaultCenter] presentNotification:notification forApplicationIdentifier:@"message_event"];
}

@end
