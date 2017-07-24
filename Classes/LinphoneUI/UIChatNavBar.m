#import "UIChatNavBar.h"
#import "PhoneMainView.h"
#import "CAAnimation+Blocks.h"

NSString *const kChatNavBarUpdate = @"ChatNavBarUpdate";

@implementation UIChatNavBar

@synthesize background;
@synthesize avatarImage;
@synthesize backButton;
@synthesize headerLabel;
@synthesize chatThread;

#pragma mark - Lifecycle Functions

- (id)init {
    self = [super initWithNibName:@"UIChatNavBar" bundle:[NSBundle mainBundle]];
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [backButton setTitle:[NSString stringWithUTF8String:"\uf053"] forState:UIControlStateNormal];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHeader:) name:kChatNavBarUpdate object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kChatNavBarUpdate object:nil];

}

- (void)viewDidLayoutSubviews
{
	int widthIn = [UIScreen mainScreen].applicationFrame.size.width;
    UIImage* tmpImg = [UIImage imageNamed:@"header_navigation_tabs_blue@2x.jpg"];
    if (widthIn == 320)
	{
        tmpImg = [UIImage imageNamed:@"header_navigation_tabs_5_blue@2x.jpg"];
    }
    else if (widthIn == 375)
	{
        tmpImg = [UIImage imageNamed:@"header_navigation_tabs_blue@2x.jpg"];
    }
    else if (widthIn == 414)
	{
        tmpImg = [UIImage imageNamed:@"header_navigation_tabs_blue@3x.jpg"];
    }
	
    background.frame = CGRectMake(0, 0, tmpImg.size.width, tmpImg.size.height);
    background.image = tmpImg;
	
    [backButton setCenter:CGPointMake(backButton.center.x,(tmpImg.size.height / 2))];
}

- (void)updateHeader:(NSNotification *)notification
{
    NSDictionary *updates = notification.userInfo;
	chatThread = updates[@"thread"];
    headerLabel.text = chatThread.remoteAddress.displayName;
	
	UIImage *avatar = chatThread.remoteAddress.avatarImage;
	if (avatar == nil)
	{
		avatar = [UIImage imageNamed:@"avatar_unknown_small.png"];
	}
    [avatarImage setImage:avatar];
	avatarImage.layer.cornerRadius = 20;
	avatarImage.layer.masksToBounds = YES;
	
    // TODO: Original To
    /*if (! [sdata[@"session_to"] isEqualToString:@""])
    {
        originalToView.hidden = NO;
        [originalToLabel setText:sdata[@"session_to"]];
    }
    else
    {
        // No Original-To
        originalToView.hidden = YES;
    }*/
}

#pragma mark - Action Functions

- (IBAction)onActionClick:(id)event
{
	NSNumber* contactNew = @YES;
	NSNumber* contactId = chatThread.contact.contactId;
	if (contactId != nil)
	{
		contactNew = @NO;
	}
	NSString* addr = chatThread.remoteAddress.address;
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
		@"context": @"chat",
		@"name": headerLabel.text,
		@"address": chatThread.remoteAddress,
		@"displayAddress": addr,
		@"new": contactNew,
	}];
	if (contactId != nil)
	{
		params[@"contact_id"] = contactId;
	}
	if (chatThread.remoteAddress.avatarImage != nil)
	{
		params[@"image"] = chatThread.remoteAddress.avatarImage;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"kRgPresentOptionsModal" object:nil userInfo:params];
}

- (IBAction)onBackClick:(id)event
{
	[[PhoneMainView instance] changeCurrentView:[MessagesViewController compositeViewDescription]];
}

#pragma mark - TPMultiLayoutViewController Functions

- (NSDictionary *)attributesForView:(UIView *)view {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
    [attributes setObject:[NSValue valueWithCGRect:view.frame] forKey:@"frame"];
    [attributes setObject:[NSValue valueWithCGRect:view.bounds] forKey:@"bounds"];
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [LinphoneUtils buttonMultiViewAddAttributes:attributes button:button];
    }
    [attributes setObject:[NSNumber numberWithInteger:view.autoresizingMask] forKey:@"autoresizingMask"];
    
    return attributes;
}

- (void)applyAttributes:(NSDictionary *)attributes toView:(UIView *)view {
    view.frame = [[attributes objectForKey:@"frame"] CGRectValue];
    view.bounds = [[attributes objectForKey:@"bounds"] CGRectValue];
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [LinphoneUtils buttonMultiViewApplyAttributes:attributes button:button];
    }
    view.autoresizingMask = [[attributes objectForKey:@"autoresizingMask"] integerValue];
}

@end
