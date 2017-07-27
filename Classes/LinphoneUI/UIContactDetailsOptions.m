//
//  UIContactDetailsOptions.m
//  ringmail
//
//  Created by Mark Baxter on 5/24/17.
//
//

#import "UIContactDetailsOptions.h"
#import "PhoneMainView.h"
#import "RgLocationManager.h"
#import "RgNetwork.h"


@implementation UIContactDetailsOptions
{
    UIView *lineView1;
    UIView *lineView2;
    UIView *lineView3;
}

@synthesize inviteButton;
@synthesize shareContactButton;
@synthesize shareLocationButton;

@synthesize contact;
@synthesize rgMember;
@synthesize disableUserFeatures;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    lineView1 = [[UIView alloc] initWithFrame:CGRectMake(0, inviteButton.frame.size.height - 2, self.view.frame.size.width - 40, 1)];
    lineView2 = [[UIView alloc] initWithFrame:CGRectMake(0, shareContactButton.frame.size.height - 2, self.view.frame.size.width - 40, 1)];
    lineView3 = [[UIView alloc] initWithFrame:CGRectMake(0, shareLocationButton.frame.size.height - 2, self.view.frame.size.width - 40, 1)];
    
    lineView1.backgroundColor = [UIColor lightGrayColor];
    lineView2.backgroundColor = [UIColor lightGrayColor];
    lineView3.backgroundColor = [UIColor lightGrayColor];
    
    [inviteButton addSubview:lineView1];
    [shareContactButton addSubview:lineView2];
    [shareLocationButton addSubview:lineView3];
    
    [[RgLocationManager sharedInstance] addObserver:self forKeyPath:kRgCurrentLocation options:NSKeyValueObservingOptionNew context:nil];
    
}

- (void)viewDidAppear:(BOOL)animated
{
//    rgMember = TRUE;  // test
    disableUserFeatures = TRUE;  // test
    
    [[RgLocationManager sharedInstance] requestWhenInUseAuthorization];
    [[RgLocationManager sharedInstance] startUpdatingLocation];
    
    shareLocationButton.hidden = TRUE;
    
    if (rgMember)
    {
        inviteButton.hidden = TRUE;
        shareContactButton.hidden = FALSE;
    }
    else
    {
        inviteButton.hidden = FALSE;
        shareContactButton.hidden = TRUE;
    }
    
    if (disableUserFeatures)
        shareContactButton.hidden = TRUE;
    
    // override -- hide invite button
    [inviteButton setHidden:YES];
}


- (void) viewDidUnload {
    [super viewDidUnload];
    [[RgLocationManager sharedInstance] removeObserver:self forKeyPath:kRgCurrentLocation context:nil];
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
    [[[LinphoneManager instance] contactManager] inviteToRingMail:contact];
}

- (IBAction)onActionShareContact:(id)event {
    NSLog(@"onActionShareContact");
}

- (IBAction)onActionShareLocation:(id)event {
    NSLog(@"onActionShareLocation");
    
//    NSString *lFirstName = CFBridgingRelease(ABRecordCopyValue(contact, kABPersonFirstNameProperty));
//    NSString *lLocalizedFirstName = [FastAddressBook localizedLabel:lFirstName];
//    
//    NSString *lLastName = CFBridgingRelease(ABRecordCopyValue(contact, kABPersonLastNameProperty));
//    NSString *lLocalizedLastName = [FastAddressBook localizedLabel:lLastName];
//    
//    ABMultiValueRef emails = ABRecordCopyValue(contact, kABPersonEmailProperty);
//    CFStringRef email = ABMultiValueCopyValueAtIndex(emails, 0);
//    NSString *lLocalizedEmail = [FastAddressBook localizedLabel:CFBridgingRelease(email)];
//    
//    NSNumber* contactNum = [NSNumber numberWithInteger:ABRecordGetRecordID((ABRecordRef)contact)];
//    NSString* contactID = [contactNum stringValue];
//    rgMember = [[[LinphoneManager instance] contactManager] dbHasRingMail:contactID];
//    
//    NSLog(@"contact: %@, %@, %@, %@", contactID, lLocalizedFirstName, lLocalizedLastName, lLocalizedEmail);
//    
//    [[RgNetwork instance] shareLocation:@{
//      @"to": @"you",
//      @"from": @"me"
//      } success:^(NSURLSessionTask *operation, id responseObject) {
//          NSDictionary* res = responseObject;
//          NSLog(@"API Response: %@", res);
//          NSString *resultValue = [res objectForKey:@"result"];
//          if (resultValue != nil && [resultValue isEqualToString:@"ok"])
//          {
//              
//          }
//          else if (resultValue != nil && [resultValue isEqualToString:@"Unauthorized"])
//          {
//              [[NSNotificationCenter defaultCenter] postNotificationName:kRgUserUnauthorized object:nil userInfo:nil];
//          }
//      } failure:^(NSURLSessionTask *operation, NSError *error) {
//          
//          NSLog(@"RingMail API Error: %@", [error localizedDescription]);
//      }];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object  change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:kRgCurrentLocation]) {
        [[RgLocationManager sharedInstance] stopUpdatingLocation];
        
        if (rgMember)
            shareLocationButton.hidden = FALSE;
        
        if (disableUserFeatures)
            shareLocationButton.hidden = TRUE;
            
    }
}


@end
