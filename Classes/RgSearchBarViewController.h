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

@interface RgSearchBarViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UITextField* addressField;
@property (nonatomic, strong) IBOutlet UICallButton* callButton;
@property (nonatomic, strong) IBOutlet UICallButton* goButton;
@property (nonatomic, strong) IBOutlet UIMessageButton* messageButton;
@property (nonatomic, strong) IBOutlet UIButton* searchButton;

@property (nonatomic, assign) BOOL visible;
@property (nonatomic, strong) NSString* placeHolder;

- (id)initWithPlaceHolder:(NSString *)placeHolder;
- (void)setAddress:(NSString*)address;

@end
