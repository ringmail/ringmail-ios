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
		[avatarImg setImage:modalData[@"image"]];
		avatarImg.contentMode = UIViewContentModeScaleAspectFit;
	}
    avatarImg.layer.cornerRadius = avatarImg.frame.size.width / 2;
    avatarImg.clipsToBounds = true;
    nameLabel.text = modalData[@"name"];
    numberLabel.text = modalData[@"address"];
	contactNew = modalData[@"new"];
	if ([contactNew boolValue])
	{
		contactLabel.text = @"Add Contact";
		numberLabel.font = [UIFont italicSystemFontOfSize:14.0f];
	}
	else
	{
		contactLabel.text = @"Contact";
		numberLabel.font = [UIFont systemFontOfSize:14.0f];
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
    NSDictionary *sessionData = [[[LinphoneManager instance] chatManager] dbGetSessionID:modalData[@"address"] to:nil contact:modalData[@"contact_id"] uuid:nil];
    [[LinphoneManager instance] setChatSession:sessionData[@"id"]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kRgDismissOptionsModal" object:nil userInfo:@{
		@"clear": @YES,
	}];
	[[PhoneMainView instance] changeCurrentView:[MessageViewController compositeViewDescription] push:TRUE];
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)onCall:(id)event
{
	ABRecordRef contact = NULL;
	if (modalData[@"contact_id"])
	{
		contact = [[[LinphoneManager instance] fastAddressBook] getContactById:modalData[@"contact_id"]];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kRgDismissOptionsModal" object:nil userInfo:@{
		@"clear": @YES,
	}];
	[RgManager startCall:modalData[@"address"] contact:contact video:NO];
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)onVideoChat:(id)event
{
	ABRecordRef contact = NULL;
	if (modalData[@"contact_id"])
	{
		contact = [[[LinphoneManager instance] fastAddressBook] getContactById:modalData[@"contact_id"]];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kRgDismissOptionsModal" object:nil userInfo:@{
		@"clear": @YES,
	}];
	[RgManager startCall:modalData[@"address"] contact:contact video:YES];
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
