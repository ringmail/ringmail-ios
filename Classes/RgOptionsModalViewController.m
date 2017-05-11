//
//  RgOptionsModalViewController.m
//  ringmail
//
//  Created by Mark Baxter on 5/3/17.
//
//

#import "RgOptionsModalViewController.h"

@interface RgOptionsModalViewController ()

@end

@implementation RgOptionsModalViewController

@synthesize contactButton;
@synthesize avatarImg;
@synthesize nameLabel;
@synthesize numberLabel;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[[UIColor clearColor] colorWithAlphaComponent:0.0]];
    
    [contactButton setTitle:[NSString stringWithUTF8String:"\uf054"] forState:UIControlStateNormal];
    
    avatarImg.layer.cornerRadius = avatarImg.frame.size.width/2;
    avatarImg.clipsToBounds = true;
}

- (void)viewWillAppear:(BOOL)animated {
//    avatarImg.image = ;
    nameLabel.text = @"First LastName";
    numberLabel.text = @"555-555-5555";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction) onContact:(id)event {
    NSLog(@"CONTACT BUTTON SELECTED");
}

-(IBAction) onText:(id)event {
    NSLog(@"TEXT BUTTON SELECTED");
}

-(IBAction) onCall:(id)event {
    NSLog(@"CALL BUTTON SELECTED");
}

-(IBAction) onVideoChat:(id)event {
     NSLog(@"VIDEO BUTTON SELECTED");
}

-(IBAction) onCancel:(id)event {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kRgDismissOptionsModal" object:nil userInfo:nil];
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}


@end
