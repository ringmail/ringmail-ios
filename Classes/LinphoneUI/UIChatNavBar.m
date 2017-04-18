#import "UIChatNavBar.h"
#import "PhoneMainView.h"
#import "CAAnimation+Blocks.h"

@implementation UIChatNavBar

@synthesize background;
@synthesize avatarImage;
@synthesize backButton;
@synthesize headerLabel;


#pragma mark - Lifecycle Functions

- (id)init {
    self = [super initWithNibName:@"UIChatNavBar" bundle:[NSBundle mainBundle]];
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateLabelsBtns:)
                                                 name:@"navBarViewChange"
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"navBarViewChange" object:nil];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [backButton setTitle:[NSString stringWithUTF8String:"\uf053"] forState:UIControlStateNormal];

}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

- (void)viewDidLayoutSubviews {
    [self setInstance: [UIScreen mainScreen].applicationFrame.size.width];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setInstance:(int)widthIn
{
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

// mrkbxt
- (void)updateLabelsBtns:(NSNotification *)notification {
    
    //NSDictionary *dict = notification.userInfo;
    
    [headerLabel setHidden:NO];
    [backButton setHidden:NO];
    [backButton setEnabled:YES];
	
	LinphoneManager *lm = [LinphoneManager instance];
    NSNumber *session = [lm chatSession];
    UIImage *image = nil;
	NSDictionary *sdata = [[lm chatManager] dbGetSessionData:session];
    NSLog(@"RingMail Chat Session Data: %@", sdata);
    NSString *displayName = sdata[@"session_tag"];
    ABRecordRef acontact = NULL;
	if (! [sdata[@"contact_id"] isKindOfClass:[NSNull class]])
	{
		acontact = [[lm fastAddressBook] getContactById:sdata[@"contact_id"]];
	}
    else
    {
		acontact = [[lm fastAddressBook] getContact:sdata[@"session_tag"]];
    }
    if (acontact != NULL)
    {
        displayName = [FastAddressBook getContactDisplayName:acontact];
        image = [FastAddressBook getContactImage:acontact thumbnail:true];
    }
    headerLabel.text = displayName;
	
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

    // Avatar
    if (image == nil) {
        image = [UIImage imageNamed:@"avatar_unknown_small.png"];
    }
    
    [avatarImage setImage:image];
	avatarImage.layer.cornerRadius = 20;
	avatarImage.layer.masksToBounds = YES;
}

#pragma mark - Event Functions

- (void)applicationWillEnterForeground:(NSNotification *)notif {

}


#pragma mark - Action Functions

- (IBAction)onBackClick:(id)event {
	[[PhoneMainView instance] popCurrentView];
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
