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
#import "NSXMLElement+XEP_0335.h"

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
@property (nonatomic, retain) FMDatabaseQueue *databaseQueue;
@property (nonatomic, retain) NSString *replyTo;

+ (NSString*)databasePath;
- (void)setupDatabase;
- (BOOL)isConnected;
- (BOOL)connectWithJID:(NSString*)myJID password:(NSString*)myPassword;
- (void)disconnect;
- (void)dropTables;
- (NSString *)sendMessageTo:(NSString*)msgTo from:(NSString*)origTo body:(NSString*)body contact:(NSNumber*)contact;
- (NSString *)sendMessageTo:(NSString*)msgTo from:(NSString*)origTo body:(NSString*)body reply:(NSString*)reply contact:(NSNumber*)contact;
- (void)sendMessageTo:(NSString*)to from:(NSString*)origTo image:(UIImage*)image contact:(NSNumber*)contact;
//- (NSString *)sendPingTo:(NSString*)to reply:(NSString*)reply contact:(NSNumber*)contact;
//- (NSString *)sendQuestionTo:(NSString*)to question:(NSString*)question answers:(NSArray*)answers contact:(NSNumber*)contact;
- (NSDictionary *)dbGetSessionID:(NSString *)from to:(NSString*)origTo contact:(NSNumber*)contact uuid:(NSString*)uuid;
- (NSDictionary*)dbGetSessionData:(NSNumber*)rowid;
- (NSArray *)dbGetSessions;
- (NSArray *)dbGetMessages:(NSNumber *)session;
- (NSArray *)dbGetMessages:(NSNumber *)session uuid:(NSString*)uuid;
- (NSString *)dbGetMessageStatusByUUID:(NSString*)uuid;
- (void)dbInsertMessage:(NSNumber *)session type:(NSString *)type data:(NSDictionary*)params uuid:(NSString*)uuid inbound:(BOOL)inbound url:(NSString*)msgUrl;
- (NSNumber *)dbGetSessionUnread;
- (void)dbDeleteSessionID:(NSNumber *)session;
- (NSNumber *)dbGetSessionByMD5:(NSString*)lookup;
- (void)dbHideSession:(NSNumber *)session;
- (NSData *)dbGetMessageData:(NSNumber*)msgId key:(NSString*)key;
- (NSData *)dbGetMessageDataByUUID:(NSString*)uuid key:(NSString*)key;
- (NSNumber*)dbUpdateMessageData:(NSData*)data forUUID:(NSString*)uuid key:(NSString*)key;
- (void)dbRemoveContact:(NSNumber*)contact;

// Component data sources
- (NSArray *)dbGetMainList;
- (NSArray *)dbGetMainList:(NSNumber *)session;
- (NSArray *)dbGetMainList:(NSNumber *)session favorites:(BOOL)fav;

- (void)dbInsertCall:(NSDictionary*)callData session:(NSNumber*)session;
- (void)dbUpdateCall:(NSDictionary*)callData;

- (void)dbAddFavorite:(NSNumber *)session;
- (void)dbDeleteFavorite:(NSNumber *)session;
- (BOOL)dbIsFavorite:(NSNumber *)session;

@end
