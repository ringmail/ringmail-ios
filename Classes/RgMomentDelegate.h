//
//  RgMomentDelegate.h
//  ringmail
//
//  Created by Mike Frager on 5/25/17.
//
//

#import <Foundation/Foundation.h>
#import "MessageViewController.h"
#import "RingKit.h"
#import "SendContactsTableViewController.h"

@interface RgMomentDelegate : NSObject<SendContactSelectDelegate>

@property (nonatomic, strong) NSString* file;
		
+ (instancetype)sharedInstance;

- (void)didSelectMultipleContacts:(NSMutableArray*)contacts;

@end
