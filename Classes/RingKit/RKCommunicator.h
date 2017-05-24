//
//  RKCommunicator.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

#import "RKThreadStore.h"
#import "RKAdapterXMPP.h"
#import "RKMessage.h"

@interface RKCommunicator : NSObject

@property (nonatomic, strong) RKAdapterXMPP* adapterXMPP;

+ (instancetype)sharedInstance;

- (void)sendMessage:(RKMessage*)message;
- (void)didReceiveMessage:(RKMessage*)message;
- (NSArray*)listThreads;
- (NSArray*)listThreadItems:(RKThread*)thread;
- (RKThread*)getThreadByAddress:(RKAddress*)remoteAddress orignalTo:(RKAddress*)origTo contactId:(NSNumber*)ctid uuid:(NSString*)uuid;

@end
