//
//  UIContactDetailsOptions.m
//  ringmail
//
//  Created by Mark Baxter on 5/24/17.
//
//

#import "UIContactDetailsOptions.h"
#import "PhoneMainView.h"


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


- (void)viewDidAppear:(BOOL)animated
{
    if (rgMember)
    {
        inviteButton.hidden = TRUE;
        shareContactButton.hidden = FALSE;
        shareLocationButton.hidden = FALSE;
    }
    else
    {
        inviteButton.hidden = FALSE;
        shareContactButton.hidden = TRUE;
        shareLocationButton.hidden = TRUE;
    }
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
//        [[[LinphoneManager instance] contactManager] inviteToRingMail:contact];
}

- (IBAction)onActionShareContact:(id)event {
    NSLog(@"onActionShareContact");
}

- (IBAction)onActionShareLocation:(id)event {
    NSLog(@"onActionShareLocation");
}

@end
