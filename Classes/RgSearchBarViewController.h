//
//  RgSearchBarViewController.h
//  ringmail
//
//  Created by Mark Baxter on 3/6/17.
//
//

#import <UIKit/UIKit.h>
#import "UICallButton.h"
#import "UIMessageButton.h"
#import "RgSearchBackgroundView.h"

@interface RgSearchBarViewController : UIViewController <UITextFieldDelegate, CAAnimationDelegate>

@property (nonatomic, strong) IBOutlet UITextField* addressField;
@property (nonatomic, strong) IBOutlet UICallButton* callButton;
@property (nonatomic, strong) IBOutlet UICallButton* goButton;
@property (nonatomic, strong) IBOutlet UIMessageButton* messageButton;
@property (nonatomic, strong) IBOutlet UIButton* searchButton;
@property (nonatomic, strong) IBOutlet UIImageView* rocketButtonImg;
@property (nonatomic, weak) IBOutlet RgSearchBackgroundView* background;
@property (nonatomic, strong) IBOutlet UILabel* addressLabel;

@property (nonatomic, assign) BOOL visible;
@property (nonatomic, strong) NSString* placeHolder;

@property (nonatomic, copy) NSString *imageName;

- (id)initWithPlaceHolder:(NSString *)placeHolder;
- (void)setAddress:(NSString*)address;
- (void)dismissKeyboard:(id)sender;

@end
