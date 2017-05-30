//
//  UIContactDetailsOptions.m
//  ringmail
//
//  Created by Mark Baxter on 5/24/17.
//
//

#import "UIContactDetailsOptions.h"
#import "PhoneMainView.h"
#import "RgLocationManager.h"


@implementation UIContactDetailsOptions
{
    UIView *lineView1;
    UIView *lineView2;
    UIView *lineView3;
}

@synthesize inviteButton;
@synthesize shareContactButton;
@synthesize shareLocationButton;

@synthesize contact;
@synthesize rgMember;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    lineView1 = [[UIView alloc] initWithFrame:CGRectMake(0, inviteButton.frame.size.height - 2, self.view.frame.size.width - 30, 1)];
    lineView2 = [[UIView alloc] initWithFrame:CGRectMake(0, shareContactButton.frame.size.height - 2, self.view.frame.size.width - 30, 1)];
    lineView3 = [[UIView alloc] initWithFrame:CGRectMake(0, shareLocationButton.frame.size.height - 2, self.view.frame.size.width - 30, 1)];
    
    lineView1.backgroundColor = [UIColor lightGrayColor];
    lineView2.backgroundColor = [UIColor lightGrayColor];
    lineView3.backgroundColor = [UIColor lightGrayColor];
    
    [inviteButton addSubview:lineView1];
    [shareContactButton addSubview:lineView2];
    [shareLocationButton addSubview:lineView3];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [[RgLocationManager sharedInstance] requestWhenInUseAuthorization];
    [[RgLocationManager sharedInstance] startUpdatingLocation];
    [[RgLocationManager sharedInstance] addObserver:self forKeyPath:kRgCurrentLocation options:NSKeyValueObservingOptionNew context:nil];
}


- (void)viewDidAppear:(BOOL)animated
{    
//    rgMember = TRUE;
    
    shareLocationButton.hidden = TRUE;
    
    if (rgMember)
    {
        inviteButton.hidden = TRUE;
        shareContactButton.hidden = FALSE;
    }
    else
    {
        inviteButton.hidden = FALSE;
        shareContactButton.hidden = TRUE;
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[RgLocationManager sharedInstance] removeObserver:self forKeyPath:kRgCurrentLocation context:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (CGFloat)height
{
    if ([[UIScreen mainScreen] bounds].size.height > 668)
        return 300;
    else
        return 230;
}


#pragma mark - Action Functions

- (IBAction)onActionInvite:(id)event {
    NSLog(@"onActionInvite");
    [[[LinphoneManager instance] contactManager] inviteToRingMail:contact];
}

- (IBAction)onActionShareContact:(id)event {
    NSLog(@"onActionShareContact");
}

- (IBAction)onActionShareLocation:(id)event {
    NSLog(@"onActionShareLocation");
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object  change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:kRgCurrentLocation]) {
        [[RgLocationManager sharedInstance] stopUpdatingLocation];
        
        if (rgMember) {
            shareLocationButton.hidden = FALSE;
            NSLog(@"stopUpdatingLocation");
        }
    }
}


@end
