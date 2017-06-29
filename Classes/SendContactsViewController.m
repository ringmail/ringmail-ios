//
//  SendContactsViewController.m
//  ringmail
//
//  Created by Mark Baxter on 6/21/17.
//
//

#import "SendContactsViewController.h"

#import "PhoneMainView.h"
#import "Utils.h"
#import "UIColor+Hex.h"

#import <AddressBook/ABPerson.h>

#import "RgContactSearchViewController.h"

@implementation SendContactsViewController

@synthesize tableController;
@synthesize tableView;
@synthesize selectionMode;
@synthesize delegate;

#pragma mark - Lifecycle Functions

- (id)init {
    self = [super initWithNibName:@"SendContactsViewController" bundle:[NSBundle mainBundle]];
	if (self)
	{
		[self setSelectionMode:SendContactSelectionModeSingle];
	}
    return self;
}

- (instancetype) initWithSelectionMode:(SendContactSelectionMode)mode
{
	self = [super init];
	if (self)
	{
		[self setSelectionMode:mode];
	}
    return self;
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if (compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"Send To"
                                                                content:@"SendContactsViewController"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 navBar:@"UINavBar"
                                                                 tabBar:@"UIMainBar"
                                                          navBarEnabled:true
                                                          tabBarEnabled:true
                                                             fullscreen:false
                                                          landscapeMode:[LinphoneManager runningOnIpad]
                                                           portraitMode:true];
    }
    return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.sectionIndexColor = [UIColor colorWithHex:@"#0A60FF"];
    self.tableView.sectionIndexBackgroundColor = [UIColor colorWithHex:@"#FFFFFF" alpha:0.33f];
    
    self.tableController.delegate = self.delegate;
    self.tableController.selectionMode = self.selectionMode;
    
    [self update];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [tableController.tableView setBackgroundColor:[UIColor clearColor]]; // Can't do it in Xib: issue with ios4
    [tableController.tableView setBackgroundView:nil];					 // Can't do it in Xib: issue with ios4
}

#pragma mark -

- (void)update {
    [tableController loadData];
}

- (void)contactsUpdated:(NSNotification *)notif {
    [tableController loadData];
}

@end
