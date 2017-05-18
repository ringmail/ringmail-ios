//
//  RgContactSearchViewController.m
//  ringmail
//
//  Created by Mark Baxter on 5/18/17.
//
//

#import "RgContactSearchViewController.h"
#import "UIColor+Hex.h"


@implementation RgContactSearchViewController

@synthesize searchField;


- (id)init
{
    return [super initWithNibName:@"RgContactSearchViewController" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSTextAttachment* attachment = [[NSTextAttachment alloc] init];
    attachment.image = [UIImage imageNamed:@"icon_search.png"];
    
    attachment.bounds = CGRectMake(0, -2, attachment.image.size.width, attachment.image.size.height);
    NSMutableAttributedString*  placeholderImageString = [[NSAttributedString attributedStringWithAttachment:attachment] mutableCopy];
    
    NSDictionary *attrDict = @{
                               NSFontAttributeName : [UIFont fontWithName:@"SFUIText-Regular" size:15],
                               NSForegroundColorAttributeName : [UIColor colorWithHex:@"#353535"]
                               };
    
    NSMutableAttributedString* placeholderString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@" Search", nil) attributes:attrDict];
    
    [placeholderImageString appendAttributedString:placeholderString];
    
    searchField.attributedPlaceholder = placeholderImageString;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Text Field Functions

-(void)dismissKeyboard:(id)sender
{
    [self.view endEditing:YES];
    [searchField setText:@""];
    [searchField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == searchField) {
        [searchField resignFirstResponder];
        [searchField setText:@""];
    }
    return YES;
}

@end
