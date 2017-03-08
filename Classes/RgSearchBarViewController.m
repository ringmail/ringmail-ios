//
//  RgSearchBarViewController.m
//  ringmail
//
//  Created by Mark Baxter on 3/6/17.
//
//

#import "RgSearchBarViewController.h"
#import "UIColor+Hex.h"
#import "Utils.h"

@implementation RgSearchBarViewController

@synthesize addressField;
@synthesize callButton;
@synthesize goButton;
@synthesize messageButton;
@synthesize searchButton;
@synthesize placeHolder;
@synthesize rocketButtonImg;
@synthesize background;


- (id)init
{
    return [super initWithNibName:@"RgSearchBarViewController" bundle:nil];
}

-(id)initWithPlaceHolder:(NSString *)placeHolder_
{
    self = [super initWithNibName:@"RgSearchBarViewController" bundle:nil];
    if (self) {
        self.placeHolder = placeHolder_;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [callButton setEnabled:TRUE];
    
    NSAttributedString *placeHolderString = [[NSAttributedString alloc] initWithString:placeHolder
        attributes:@{
                     NSForegroundColorAttributeName:[UIColor colorWithHex:@"#222222"],
                     NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Light" size:16]
                     }];
    addressField.attributedPlaceholder = placeHolderString;
    addressField.font = [UIFont fontWithName:@"SFUIText-Light" size:16];
    addressField.textColor = [UIColor colorWithHex:@"#222222"];
    addressField.text = @"";
    addressField.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}


- (IBAction)onAddressChange:(id)sender {
    
    if ([[addressField text] length] > 0) {
        NSString* addr = [addressField text];
        if ([[addr substringToIndex:1] isEqualToString:@"#"])
        {
            messageButton.hidden = YES;
            callButton.hidden = YES;
            goButton.hidden = NO;
        }
        else
        {
            messageButton.hidden = NO;
            callButton.hidden = NO;
            goButton.hidden = YES;
        }
    } else {
        messageButton.hidden = YES;
        callButton.hidden = YES;
        goButton.hidden = YES;
    }
}


- (IBAction)onSearch:(id)sender {
    
    background.sepLineVisible = NO;
    [background setNeedsDisplay];
    
    searchButton.enabled = NO;
    rocketButtonImg.hidden = YES;
    
    UIImageView *rocketAnimImg =[[UIImageView alloc] initWithFrame:CGRectMake(0,0,50,50)];
    rocketAnimImg.image=[UIImage imageNamed:@"hashtag_rocket_icon_blue.png"];
    [self.view addSubview:rocketAnimImg];
    
    [CATransaction begin];

    [CATransaction setCompletionBlock:^{
        
        [CATransaction begin];
        
        [CATransaction setCompletionBlock:^{
            [rocketAnimImg.layer removeAllAnimations];
            [rocketAnimImg removeFromSuperview];
            rocketButtonImg.hidden = NO;
            addressField.hidden = NO;
            [addressField becomeFirstResponder];
            background.sepLineVisible = YES;
            [background setNeedsDisplay];
        }];
        
        CABasicAnimation *animation3 = [CABasicAnimation animation];
        animation3.keyPath = @"position.x";
        animation3.fromValue = @-25;
        animation3.toValue = @25;
        animation3.duration = 0.25f;
        animation3.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        animation3.fillMode = kCAFillModeForwards;
        animation3.removedOnCompletion = NO;
        [rocketAnimImg.layer addAnimation:animation3 forKey:@"flight_return"];
        
        CAKeyframeAnimation *animation4 = [CAKeyframeAnimation animation];
        animation4 = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation4.duration = 0.25f;
        animation4.cumulative = YES;
        animation4.repeatCount = 0;
        animation4.values = [NSArray arrayWithObjects:
                             [NSNumber numberWithFloat:0.25 * M_PI],
                             [NSNumber numberWithFloat:0.0 * M_PI],nil];
        animation4.keyTimes = [NSArray arrayWithObjects:
                               [NSNumber numberWithFloat:0],
                               [NSNumber numberWithFloat:1.0], nil];
        animation4.timingFunctions = [NSArray arrayWithObjects:
                                      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], nil];
        animation4.fillMode = kCAFillModeForwards;
        animation4.removedOnCompletion = NO;
        [rocketAnimImg.layer addAnimation:animation4 forKey:@"reverse_rotate_return"];
        
        [CATransaction commit];
        
    }];

    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.duration = 0.25f;
    animation.cumulative = YES;
    animation.repeatCount = 0;
    animation.values = [NSArray arrayWithObjects:
                        [NSNumber numberWithFloat:0.0 * M_PI],
                        [NSNumber numberWithFloat:0.25 * M_PI],nil];
    animation.keyTimes = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:0],
                          [NSNumber numberWithFloat:1.0], nil];
    animation.timingFunctions = [NSArray arrayWithObjects:
                                 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], nil];
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    [rocketAnimImg.layer addAnimation:animation forKey:@"liftoff"];
    

    CABasicAnimation *animation2 = [CABasicAnimation animation];
    animation2.keyPath = @"position.x";
    animation2.fromValue = @25;
    animation2.toValue = @455;
    animation2.duration = 0.75f;
    animation2.fillMode = kCAFillModeForwards;
    animation2.removedOnCompletion = NO;
    animation2.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.5:0:0.9:0.7];
    [rocketAnimImg.layer addAnimation:animation2 forKey:@"flight"];

    
    [CATransaction commit];
    
}


- (void)setAddress:(NSString *)address {
    [addressField setText:address];
}


#pragma mark - Text Field Functions

-(void)dismissKeyboard:(id)sender
{
    [self.view endEditing:YES];
    [addressField setText:@""];
    addressField.hidden = YES;
    searchButton.enabled = YES;
}


#pragma mark - UITextFieldDelegate Functions

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == addressField) {
        [goButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        [addressField resignFirstResponder];
        [addressField setText:@""];
        addressField.hidden = YES;
        searchButton.enabled = YES;
    }
    return YES;
}

@end
