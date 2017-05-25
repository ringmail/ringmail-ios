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
    // Do any additional setup after loading the view from its nib.
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
