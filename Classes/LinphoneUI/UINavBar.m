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

typedef enum {
    Ring, Explore, Recents, Contacts, Settings, HTagCard, Chat
} NavView;

int backState = 0;

@synthesize background;
@synthesize backButton;
@synthesize segmentButton;
@synthesize headerLabel;
@synthesize leftLabel;
@synthesize rightLabel;


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
    CGRect segFrame = segmentButton.frame;
    UIImage* tmpImg = [UIImage imageNamed:@"header_navigation_tabs_blue@2x.jpg"];
    double segFrameHeight = 27;
    double segFrameWidth = 170;
    double segXShifted = segFrame.origin.x;

    if (widthIn == 320) {
        tmpImg = [UIImage imageNamed:@"header_navigation_tabs_5_blue@2x.jpg"];
        segFrameHeight = 24;
        segFrameWidth = 145;
        segXShifted += 12.5;
        [backButton setCenter:CGPointMake(backButton.center.x,(tmpImg.size.height / 2))];
    }
    else if (widthIn == 375) {
        tmpImg = [UIImage imageNamed:@"header_navigation_tabs_blue@2x.jpg"];
        [backButton setCenter:CGPointMake(backButton.center.x, (tmpImg.size.height / 2))];
    }
    else if (widthIn == 414) {
        tmpImg = [UIImage imageNamed:@"header_navigation_tabs_blue@3x.jpg"];
        segFrameHeight = 30;
        segFrameWidth = 189;
        segXShifted -= 9.5;
        [backButton setCenter:CGPointMake(backButton.center.x, (tmpImg.size.height / 2))];
    }
    
    background.frame = CGRectMake(0, 0, tmpImg.size.width, tmpImg.size.height);
    background.image = tmpImg;
    [segmentButton setFrame:CGRectMake(segXShifted, segFrame.origin.y, segFrameWidth, segFrameHeight)];
    [segmentButton setCenter:CGPointMake(segmentButton.center.x,((background.frame.size.height/3)*2)+5)];
    
    if (segmentButton.hidden)
    {
        [headerLabel setCenter:CGPointMake(headerLabel.center.x,background.frame.size.height/2)];
        [leftLabel setCenter:CGPointMake(leftLabel.center.x,background.frame.size.height/2)];
        [rightLabel setCenter:CGPointMake(rightLabel.center.x,background.frame.size.height/2)];
    }
    else
    {
        [headerLabel setCenter:CGPointMake(headerLabel.center.x,(background.frame.size.height/3)+5)];
        [leftLabel setCenter:CGPointMake(leftLabel.center.x, (background.frame.size.height/3)+5)];
        [rightLabel setCenter:CGPointMake(rightLabel.center.x,(background.frame.size.height/3)+5)];
    }
}

// mrkbxt
- (void)updateLabelsBtns:(NSNotification *) notification {
    
    NSDictionary *dict = notification.userInfo;
    NSString *header = [dict valueForKey:@"header"];
    
    NSString *backStateReset = [dict valueForKey:@"backstate"];
    
    if ([backStateReset isEqual:@"reset"])
        backState = 0;
    
    if (backState && [header isEqual: @"Explore"])
        header = @"Hashtag Card";
    
    headerLabel.text = header;
    [headerLabel setHidden:NO];
    [segmentButton setTitle:[dict valueForKey:@"lSeg"] forSegmentAtIndex:0];
    [segmentButton setTitle:[dict valueForKey:@"rSeg"] forSegmentAtIndex:1];
    [leftLabel setHidden:YES];
    [rightLabel setHidden:YES];
    [backButton setHidden:YES];
    [backButton setEnabled:NO];
    
    NavView navView = [self navViewFromString:header];
    
    switch (navView)
    {
        case Ring:
        case Explore:
        case Recents:
            [segmentButton setEnabled:YES];
            [segmentButton setHidden:NO];
            break;
        case Contacts:
        case Settings:
            [segmentButton setEnabled:NO];
            [segmentButton setHidden:YES];
            break;
        case HTagCard:
            [segmentButton setEnabled:NO];
            [segmentButton setHidden:YES];
            [backButton setHidden:NO];
            [backButton setEnabled:YES];
            backState = 1;
            [headerLabel setHidden:NO];
            headerLabel.text = @"Explore";
            break;
        default:
            break;
    }
}


- (NavView)navViewFromString:(NSString*) sIn {
    
    NSDictionary<NSString*,NSNumber*> *navViews = @{
        @"RingMail": @(Ring),
        @"Explore": @(Explore),
        @"Recent Activity": @(Recents),
        @"Contacts": @(Contacts),
        @"Settings": @(Settings),
        @"Hashtag Card": @(HTagCard),
    };
    
    return [[navViews valueForKey:sIn] intValue];
}


#pragma mark - Event Functions

- (void)applicationWillEnterForeground:(NSNotification *)notif {

}


#pragma mark - Action Functions

- (IBAction)onBackClick:(id)event {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RgHashtagDirectoryUpdatePath" object:self userInfo:@{@"category_id": @"0",}];
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
