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
    [addressField becomeFirstResponder];
}


- (void)setAddress:(NSString *)address {
    [addressField setText:address];
}


#pragma mark - Text Field Functions

-(void)dismissKeyboard:(id)sender
{
    [self.view endEditing:YES];
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
    }
    return YES;
}

@end
