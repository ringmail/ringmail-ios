//
//  UINavBar.h
//  ringmail
//
//  Created by Mark Baxter on 2/3/17.
//
//

#import <UIKit/UIKit.h>
#import "TPMultiLayoutViewController.h"


//@class UINavBar;
//@protocol UINavBarDelegate <NSObject>
//-(void) didSelectUINavBar:(UINavBar *) sender;
//@end


@interface UINavBar : TPMultiLayoutViewController

//@property (nonatomic, weak) id <UINavBarDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIImageView* background;
@property (nonatomic, strong) IBOutlet UIButton* backButton;
@property (nonatomic, strong) IBOutlet UISegmentedControl* segmentButton;
@property (nonatomic, strong) IBOutlet UILabel* headerLabel;
@property (nonatomic, strong) IBOutlet UILabel* leftLabel;
@property (nonatomic, strong) IBOutlet UILabel* rightLabel;

-(IBAction) onBackClick: (id) event;
-(IBAction) segmentedControlChanged:(id)sender;

- (void)setInstance:(int)widthIn;
- (void)updateLabelsBtns:(NSNotification *) notification;

@end
