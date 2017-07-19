//
//  RgOptionsModalViewController.m
//  ringmail
//
//  Created by Mark Baxter on 5/3/17.
//
//

#import "RgOptionsModalViewController.h"
#import "ContactDetailsViewController.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"

@interface RgOptionsModalViewController ()

@end

@implementation RgOptionsModalViewController

@synthesize modalData;
@synthesize contactButton;
@synthesize avatarImg;
@synthesize nameLabel;
@synthesize numberLabel;
@synthesize contactLabel;
@synthesize contactNew;
@synthesize chatButton;

- (id)initWithData:(NSDictionary*)param
{
	self = [super init];
	if (self)
	{
		modalData = param;
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[[UIColor clearColor] colorWithAlphaComponent:0.0]];
    [contactButton setTitle:[NSString stringWithUTF8String:"\uf054"] forState:UIControlStateNormal];
	if (modalData[@"image"])
	{
		avatarImg.contentMode = UIViewContentModeScaleAspectFit;
		avatarImg.image = modalData[@"image"];
	}
    avatarImg.layer.cornerRadius = avatarImg.frame.size.width / 2;
    avatarImg.clipsToBounds = YES;
    nameLabel.text = modalData[@"name"];
    numberLabel.text = modalData[@"displayAddress"];
	contactNew = modalData[@"new"];
	if ([contactNew boolValue])
	{
		contactLabel.text = @"Add To Contact";
		numberLabel.font = [UIFont italicSystemFontOfSize:14.0f];
	}
	else
	{
		contactLabel.text = @"View Contact";
		numberLabel.font = [UIFont systemFontOfSize:14.0f];
	}
	if ([modalData[@"context"] isEqualToString:@"chat"])
	{
		chatButton.hidden = YES;
	}
	else
	{
		chatButton.hidden = NO;
	}
}

- (IBAction)onContact:(id)event
{
	if (modalData[@"contact_id"])
	{
		ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContactById:modalData[@"contact_id"]];
    	ContactDetailsViewController *controller = DYNAMIC_CAST(
    		[[PhoneMainView instance] changeCurrentView:[ContactDetailsViewController compositeViewDescription] push:TRUE],
    		ContactDetailsViewController);
    	if (controller != nil)
		{
   			[controller setContact:contact];
    	}
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kRgDismissOptionsModal" object:nil userInfo:@{
			@"clear": @NO,
		}];
        [[self presentingViewController] dismissViewControllerAnimated:YES completion:NULL];
	}
}

- (IBAction)onText:(id)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kRgDismissOptionsModal" object:nil userInfo:@{
		@"clear": @YES,
	}];
	RKCommunicator *comm = [RKCommunicator sharedInstance];
	RKThread *thread = [comm getThreadByAddress:modalData[@"address"]];
	if (thread != nil)
	{
		[[RKCommunicator sharedInstance] startMessageView:thread];
	}
	else
	{
		NSAssert(FALSE, @"Invalid thread for address: '%@'", modalData[@"address"]);
	}
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)onCall:(id)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kRgDismissOptionsModal" object:nil userInfo:@{
		@"clear": @YES,
	}];
	[[RKCommunicator sharedInstance] startCall:modalData[@"address"] video:NO];
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)onVideoChat:(id)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kRgDismissOptionsModal" object:nil userInfo:@{
		@"clear": @YES,
	}];
	[[RKCommunicator sharedInstance] startCall:modalData[@"address"] video:YES];
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)onCancel:(id)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kRgDismissOptionsModal" object:nil userInfo:@{
		@"clear": @NO,
	}];
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end
