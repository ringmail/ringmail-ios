//
//  RKAdapterXMPP.h
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

@interface RKAdapterXMPP : NSObject

@property (nonatomic) dispatch_queue_t workQueue;
@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPMessageDeliveryReceipts *xmppDeliveryReceipts;
@property (nonatomic, strong) XMPPJID *JID;
@property (nonatomic, retain) NSString* replyTo;
@property (nonatomic, strong) NSString* chatPassword;

- (BOOL)connectWithJID:(NSString*)myJID password:(NSString*)myPassword;
- (BOOL)isConnected;
- (void)disconnect;

@end
