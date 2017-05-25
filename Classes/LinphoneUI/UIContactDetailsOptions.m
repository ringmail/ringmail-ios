//
//  UIContactDetailsOptions.m
//  ringmail
//
//  Created by Mark Baxter on 5/24/17.
//
//

#import "UIContactDetailsOptions.h"


@implementation UIContactDetailsOptions

@synthesize inviteButton;
@synthesize shareContactButton;
@synthesize shareLocationButton;


- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(15, self.view.frame.size.height - 1, self.view.frame.size.width - 30, 1)];
    lineView.backgroundColor = [UIColor lightGrayColor];
    [inviteButton addSubview:lineView];
    [shareContactButton addSubview:lineView];
    [shareLocationButton addSubview:lineView];
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
}

- (IBAction)onActionShareContact:(id)event {
    NSLog(@"onActionShareContact");
}

- (IBAction)onActionShareLocation:(id)event {
    NSLog(@"onActionShareLocation");
}

@end
