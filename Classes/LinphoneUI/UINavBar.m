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
    
    [self setInstance: [UIScreen mainScreen].applicationFrame.size.width];
    
    [backButton setTitle:[NSString stringWithUTF8String:"\uf053"] forState:UIControlStateNormal];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setInstance:(int)widthIn
{

//    [self.delegate didSelectUINavBar:self];


//    buttonArray = [[NSArray alloc] initWithObjects:historyButton,contactsButton,dialerButton,hashtagButton,settingsButton,nil];
    
//    NSArray *imgPrefix =  [NSArray arrayWithObjects:@"tabs_recents%@%@",@"tabs_contacts%@%@",@"tabs_ring%@%@",@"tabs_explore%@%@",@"tabs_settings%@%@",nil];
//    NSArray *imgSuffix = [NSArray arrayWithObjects:@"_5@2x",@"@2x",@"@3x",nil];
//    NSArray *imgState = [NSArray arrayWithObjects:@"_normal",@"_pressed",@"_selected",nil];
//    
//    int i = 0; int j = 0;
    
    CGRect segFrame = segmentButton.frame;
    
    if (widthIn == 320) {
        background.image = [UIImage imageNamed:@"header_navigation_tabs_5_blue@2x.jpg"];
        [segmentButton setFrame:CGRectMake(segFrame.origin.x, segFrame.origin.y, segFrame.size.width, 24.0)];
    }
    else if (widthIn == 375) {
        background.image = [UIImage imageNamed:@"header_navigation_tabs_blue@2x.jpg"];
        [segmentButton setFrame:CGRectMake(segFrame.origin.x, segFrame.origin.y, segFrame.size.width, 27.0)];
//        j = 1;
    }
    else if (widthIn == 414) {
        background.image = [UIImage imageNamed:@"header_navigation_tabs_blue@3x.jpg"];
        [segmentButton setFrame:CGRectMake(segFrame.origin.x, segFrame.origin.y, segFrame.size.width, 30.0)];
//        j = 2;
    }
    
//    for (UIButton* btn in buttonArray) {
//        NSString *tabNorm = [NSString stringWithFormat:imgPrefix[i], imgState[0], imgSuffix[j]];
//        NSString *tabPres = [NSString stringWithFormat:imgPrefix[i], imgState[1], imgSuffix[j]];
//        NSString *tabSele = [NSString stringWithFormat:imgPrefix[i], imgState[2], imgSuffix[j]];
//        
//        [btn setImage:[UIImage imageNamed:tabNorm] forState:UIControlStateNormal];
//        [btn setImage:[UIImage imageNamed:tabPres] forState:UIControlStateHighlighted];
//        [btn setImage:[UIImage imageNamed:tabSele] forState:UIControlStateSelected];
//        
//        CGSize imageSize = btn.imageView.image.size;
//        btn.titleEdgeInsets = UIEdgeInsetsMake(imageSize.height, -imageSize.width, 0.0, 0.0);
//        
//        i++;
//    }
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
