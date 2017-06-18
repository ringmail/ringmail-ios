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
#import "LinphoneManager.h"
#import "RingKit.h"

@implementation RgSearchBarViewController

@synthesize addressField;
@synthesize goButton;
@synthesize triangleButton;
@synthesize searchButton;
@synthesize placeHolder;
@synthesize rocketButtonImg;
@synthesize background;
@synthesize addressLabel;

bool animInactive = YES;


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
    self.view.clipsToBounds = YES;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissOptionsModal:) name:kRgDismissOptionsModal object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgDismissOptionsModal object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
    addressLabel.layer.opacity = 0.0;
    addressLabel.text = placeHolder;
    
    animInactive = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

- (void)dismissOptionsModal:(NSNotification *)notif
{
    if ([notif.userInfo[@"clear"] boolValue])
	{
		[addressField setText:@""];
	}
}

- (IBAction)onAddressChange:(id)sender {
    
    if ([[addressField text] length] > 0) {
        NSString* addr = [addressField text];
        if ([[addr substringToIndex:1] isEqualToString:@"#"])
        {
            triangleButton.hidden = YES;
            goButton.hidden = NO;
        }
        else
        {
            triangleButton.hidden = NO;
            goButton.hidden = YES;
        }
    }
	else
	{
        goButton.hidden = YES;
        triangleButton.hidden = YES;
    }
}


- (IBAction)onSearch:(id)sender
{
    bool addressActive = [addressField isFirstResponder];
    bool addressEmpty = [addressField.text isEqual:@""];
    
    if (!addressActive && addressEmpty)
        [self animateRocket:YES];
    else
    {
        [addressField resignFirstResponder];
        addressLabel.layer.opacity = 0.0;
        [addressField setText:@""];
    }
}

- (IBAction)onTriangleButton:(id)sender
{
	NSString* address = addressField.text;
	RKAddress *raddress = [RKAddress newWithString:address];
	
    // Contact ID lookup attemp
	ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
	UIImage *customImage = nil;
	NSString *name = [address copy];
	NSString *addr = @"New ";
	if ([raddress isPhone])
	{
		addr = [addr stringByAppendingString:@"Number"];
	}
	else
	{
		addr = [addr stringByAppendingString:@"Address"];
	}
	NSNumber *contactNew = @YES;
	NSNumber *contactId = nil;
	if (contact)
	{
        //LOGI(@"RingMail: Matched contact for options modal");
		customImage = [FastAddressBook getContactImage:contact thumbnail:true];
        name = [FastAddressBook getContactDisplayName:contact];
		addr = [address copy];
		contactNew = @NO;
		contactId = [[[LinphoneManager instance] fastAddressBook] getContactId:contact];
	}
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
		@"context": @"navbar",
		@"name": name,
		@"address": raddress,
		@"displayAddress": addr,
		@"new": contactNew,
	}];
	if (customImage != nil)
	{
		params[@"image"] = customImage;
	}
	if (contactId != nil)
	{
		params[@"contact_id"] = contactId;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kRgPresentOptionsModal" object:nil userInfo:params];
}

-(void)animateRocket:(bool)activeAddress
{
    if (animInactive)
    {
        animInactive = NO;
        
        background.sepLineVisible = NO;
        [background setNeedsDisplay];
        
        rocketButtonImg.hidden = YES;
        addressLabel.layer.opacity = 0.0;
        
        CGFloat addressX = addressLabel.layer.position.x;
		
        UIImageView *rocketAnimImg = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,50,50)];
        rocketAnimImg.image = [UIImage imageNamed:@"hashtag_rocket_icon_blue.png"];
        [self.view addSubview:rocketAnimImg];
        
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                [rocketAnimImg.layer removeAllAnimations];
                [rocketAnimImg removeFromSuperview];
                [addressLabel.layer removeAllAnimations];
                animInactive = YES;
                addressLabel.layer.opacity = 0.0;
            }];
            
            if (activeAddress)
            {
                CABasicAnimation *animation6a = [CABasicAnimation animation];
                animation6a.keyPath = @"opacity";
                animation6a.toValue = @1;
                animation6a.toValue = @0;
                animation6a.beginTime = CACurrentMediaTime() + 2.0f;
                animation6a.duration = 0.75f;
                animation6a.fillMode = kCAFillModeForwards;
                animation6a.removedOnCompletion = NO;
                animation6a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
                [addressLabel.layer addAnimation:animation6a forKey:@"text_disappear"];
                
                CABasicAnimation *animation6b = [CABasicAnimation animation];
                animation6b.keyPath = @"position.x";
                animation6b.fromValue = [NSNumber numberWithFloat:addressX];
                animation6b.toValue = [NSNumber numberWithFloat:addressX + 50];
                animation6b.beginTime = CACurrentMediaTime() + 2.0f;
                animation6b.duration = 0.75f;
                animation6b.fillMode = kCAFillModeForwards;
                animation6b.removedOnCompletion = NO;
                animation6b.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
                [addressLabel.layer addAnimation:animation6b forKey:@"text_slide_out"];
            }
            
            [CATransaction commit];
            
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                    rocketButtonImg.hidden = NO;
                    background.sepLineVisible = YES;
                    [background setNeedsDisplay];
            }];
            
            CABasicAnimation *animation4 = [CABasicAnimation animation];
            animation4.keyPath = @"position.x";
            animation4.fromValue = @-25;
            animation4.toValue = @25;
            animation4.duration = 0.25f;
            animation4.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            animation4.fillMode = kCAFillModeForwards;
            animation4.removedOnCompletion = NO;
            [rocketAnimImg.layer addAnimation:animation4 forKey:@"flight_return"];
            
            CAKeyframeAnimation *animation5 = [CAKeyframeAnimation animation];
            animation5 = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
            animation5.duration = 0.25f;
            animation5.cumulative = YES;
            animation5.repeatCount = 0;
            animation5.values = [NSArray arrayWithObjects:
                                 [NSNumber numberWithFloat:0.25 * M_PI],
                                 [NSNumber numberWithFloat:0.0 * M_PI],nil];
            animation5.keyTimes = [NSArray arrayWithObjects:
                                   [NSNumber numberWithFloat:0],
                                   [NSNumber numberWithFloat:1.0], nil];
            animation5.timingFunctions = [NSArray arrayWithObjects:
                                          [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], nil];
            animation5.fillMode = kCAFillModeForwards;
            animation5.removedOnCompletion = NO;
            [rocketAnimImg.layer addAnimation:animation5 forKey:@"reverse_rotate_return"];
			
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
        
        if (activeAddress)
        {
            CABasicAnimation *animation3a = [CABasicAnimation animation];
            animation3a.keyPath = @"opacity";
            animation3a.toValue = @1;
            animation3a.duration = 0.5f;
            animation3a.beginTime = CACurrentMediaTime() + 0.25f;
            animation3a.fillMode = kCAFillModeForwards;
            animation3a.removedOnCompletion = NO;
            animation3a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            [addressLabel.layer addAnimation:animation3a forKey:@"text_appear"];
            
            CABasicAnimation *animation3b = [CABasicAnimation animation];
            animation3b.keyPath = @"position.x";
            animation3b.fromValue = @25;
            animation3b.toValue = [NSNumber numberWithFloat:addressX];
            animation3b.duration = 0.5f;
            animation3b.beginTime = CACurrentMediaTime() + 0.25f;
            animation3b.fillMode = kCAFillModeForwards;
            animation3b.removedOnCompletion = NO;
            animation3b.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            [addressLabel.layer addAnimation:animation3b forKey:@"text_slide"];
        }
        
        [CATransaction commit];
    }
    
}


- (void)setAddress:(NSString *)address {
    [addressField setText:address];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([[touch.view class] isSubclassOfClass:[RgSearchBackgroundView class]]) {
		// ???
    }
}

#pragma mark - Text Field Functions

-(void)dismissKeyboard:(id)sender
{
    [self.view endEditing:YES];
    [addressField setText:@""];
    [addressField resignFirstResponder];
}


#pragma mark - UITextFieldDelegate Functions

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == addressField) {
        if (![addressField.text isEqual:@""]) {
            [self animateRocket:NO];
            [goButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
        [addressField resignFirstResponder];
        [addressField setText:@""];
    }
    return YES;
}

@end
