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

@synthesize contactView;
@synthesize invalidView;

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
    
    // TODO: check for domain, domains are not contacts...
    NSString *address = modalData[@"address"];
    ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
    UIImage *customImage = nil;
    NSString *name = [address copy];
    NSString *addr = @"New ";
    
    if ([RKAddress validAddress: address])
    {
        RKAddress *raddress = [RKAddress newWithString:address];
        
        if ([raddress isPhone])
            addr = [addr stringByAppendingString:@"Number"];
        else
            addr = [addr stringByAppendingString:@"Address"];
        
        NSNumber *contactIsNew = @YES;
        NSNumber *contactId = nil;
        
        if (contact)
        {
            name = [FastAddressBook getContactDisplayName:contact];
            addr = [address copy];
            contactIsNew = @NO;
            contactId = [[[LinphoneManager instance] fastAddressBook] getContactId:contact];
            customImage = [FastAddressBook getContactImage:contact thumbnail:true];
            if (customImage)
            {
                avatarImg.contentMode = UIViewContentModeScaleAspectFit;
                avatarImg.image = customImage;
            }
        }
        
        avatarImg.layer.cornerRadius = avatarImg.frame.size.width / 2;
        avatarImg.clipsToBounds = YES;
        
        nameLabel.text = name;
        numberLabel.text = addr;
        numberLabel.font = [UIFont italicSystemFontOfSize:14.0f];
        
        if ([contactIsNew boolValue])
            contactLabel.text = @"Add To Contact";
        else
            contactLabel.text = @"View Contact";
        
        if ([modalData[@"context"] isEqualToString:@"chat"])
            chatButton.hidden = YES;
        else
            chatButton.hidden = NO;
        
        contactView.hidden = false;
        invalidView.hidden = true;
    }
    else
    {
        contactView.hidden = true;
        invalidView.hidden = false;
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
