//
//  RgChatManager.h
//  ringmail
//
//  Created by Mike Frager on 9/1/15.
//
//

#import <Foundation/Foundation.h>

#import "XMPPFramework.h"
#import "XMPPReconnect.h"
#import "XMPPCapabilities.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "RegexKitLite/RegexKitLite.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"
#import "RgManager.h"

@interface RgChatManager : NSObject

@property (nonatomic) dispatch_queue_t workQueue;
@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong) XMPPJID *JID;

- (BOOL)connectWithJID:(NSString*) myJID password:(NSString*)myPassword;
- (NSArray *)dbGetSessions;
- (NSArray *)dbGetMessages:(NSString *)from;

@end
