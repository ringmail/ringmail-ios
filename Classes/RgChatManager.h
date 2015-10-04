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
#import "XMPPCoreDataStorage.h"
#import "XMPPCapabilities.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPvCardTempModule.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPMessageDeliveryReceipts.h"
#import "XMPPMessage+XEP_0184.h"

#import "RegexKitLite/RegexKitLite.h"
#import "JSQMessages.h"
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
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPMessageDeliveryReceipts *xmppDeliveryReceipts;
@property (nonatomic, strong) XMPPJID *JID;
@property (atomic, strong) NSString* chatPassword;

- (BOOL)isConnected;
- (BOOL)connectWithJID:(NSString*) myJID password:(NSString*)myPassword;
- (void)disconnect;
- (void)dropTables;
- (void)sendMessageTo:(NSString*)msgTo body:(NSString*)body;
- (void)sendMessageTo:(NSString*)to image:(UIImage*)image;
- (NSArray *)dbGetSessions;
- (NSArray *)dbGetMessages:(NSString *)from;
- (void)dbInsertMessage:(NSString *)from type:(NSString *)type data:(NSObject*)data uuid:(NSString*)uuid inbound:(BOOL)inbound url:(NSString*)msgUrl;
- (NSNumber *)dbGetSessionUnread;
- (void)dbDeleteSessionID:(NSString *)from;
- (NSString *)dbGetSessionByMD5:(NSString*)lookup;
- (NSData *)dbGetMessageData:(NSNumber*)msgId;
- (void)dbUpdateMessageData:(NSData*)data forUUID:(NSString*)uuid;

@end
