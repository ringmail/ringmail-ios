//
//  UINavBar.m
//  ringmail
//
//  Created by Mark Baxter on 2/3/17.
//
//

#import "UINavBar.h"
#import "PhoneMainView.h"
#import "CAAnimation+Blocks.h"


@implementation UINavBar

static NSString *const kBounceAnimation = @"bounce";
static NSString *const kAppearAnimation = @"appear";
static NSString *const kDisappearAnimation = @"disappear";

@synthesize background;
@synthesize backButton;
@synthesize segmentButton;
@synthesize headerLabel;
@synthesize leftLabel;
@synthesize rightLabel;

//@synthesize delegate;

#pragma mark - Lifecycle Functions

- (id)init {
    self = [super initWithNibName:@"UINavBar" bundle:[NSBundle mainBundle]];
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateLabels:)
                                                 name:@"navBarViewChange"
                                               object:nil];

//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(changeViewEvent:)
//                                                 name:kLinphoneMainViewChange
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(callUpdate:)
//                                                 name:kLinphoneCallUpdate
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(textReceived:)
//                                                 name:kRgTextReceived
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(settingsUpdate:)
//                                                 name:kLinphoneSettingsUpdate
//                                               object:nil];
//    [self update:FALSE];
//    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"navBarViewChange" object:nil];
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneMainViewChange object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneTextReceived object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneSettingsUpdate object:nil];
    
    //missedCalls = [NSNumber numberWithInt:0];
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
    CGRect segFrame = segmentButton.frame;
    UIImage* tmpImg = [UIImage imageNamed:@"header_navigation_tabs_blue@2x.jpg"];
    double segFrameHeight = 27;
    double segFrameWidth = 170;

    if (widthIn == 320) {
        tmpImg = [UIImage imageNamed:@"header_navigation_tabs_5_blue@2x.jpg"];
        segFrameHeight = 24;
        segFrameWidth = 145;
    }
    else if (widthIn == 375) {
        tmpImg = [UIImage imageNamed:@"header_navigation_tabs_blue@2x.jpg"];
//        segFrameHeight = 27;
//        segFrameWidth = 170;
    }
    else if (widthIn == 414) {
        tmpImg = [UIImage imageNamed:@"header_navigation_tabs_blue@3x.jpg"];
        segFrameHeight = 30;
        segFrameWidth = 189;
    }
    
    background.frame = CGRectMake(0, 0, tmpImg.size.width, tmpImg.size.height);
    background.image = tmpImg;
    [segmentButton setFrame:CGRectMake(segFrame.origin.x, segFrame.origin.y, segFrameWidth, segFrameHeight)];
    
}

// mrkbxt
- (void)updateLabels:(NSNotification *) notification {
    NSDictionary *dict = notification.userInfo;
    NSString *header = [dict valueForKey:@"header"];
    NSString *lSeg = [dict valueForKey:@"lSeg"];
    NSString *rSeg = [dict valueForKey:@"rSeg"];
    
    if (header != nil) {
        headerLabel.text = header;
        [segmentButton setTitle:lSeg forSegmentAtIndex:0];
        [segmentButton setTitle:rSeg forSegmentAtIndex:1];
    }
}


#pragma mark - Event Functions

- (void)applicationWillEnterForeground:(NSNotification *)notif {
    // Force the animations
//    [[self.view layer] removeAllAnimations];
//    [chatNotificationView.layer setTransform:CATransform3DIdentity];
//    [chatNotificationView setHidden:TRUE];
//    [self update:FALSE];
}


#pragma mark - Action Functions

- (IBAction)onBackClick:(id)event {
//    [[PhoneMainView instance] changeCurrentView:[RgFavoriteViewController compositeViewDescription]];
}


- (IBAction)segmentedControlChanged:(id)sender
{
    UISegmentedControl *s = (UISegmentedControl *)sender;
    
    NSDictionary* dict = [NSDictionary dictionaryWithObject: [NSString stringWithFormat: @"%ld", s.selectedSegmentIndex] forKey:@"segIndex"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RgSegmentControl" object:nil userInfo:dict];

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
