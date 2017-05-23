//
//  RKAdapterXMPP.m
//  ringmail
//
//  Created by Mike Frager on 9/1/15.
//
//

#import "RKAdapterXMPP.h"
#import "RgManager.h"
#import "RgNetwork.h"
#import "NSString+MD5.h"
#import "NSXMLElement+XMPP.h"
#import "RKAddress.h"
#import "RKContact.h"
#import "RKThread.h"
#import "RKMessage.h"
#import "RKCommunicator.h"

#define THIS_METHOD NSStringFromSelector(_cmd)

@implementation RKAdapterXMPP

@synthesize chatPassword;

- (id)init
{
    if (self = [super init])
    {
        NSString *queueLabel = [NSString stringWithFormat:@"%@.work.%@", [self class], self];
        self.workQueue = dispatch_queue_create([queueLabel UTF8String], 0);
        self.chatPassword = @"";
        self.replyTo = @"";
        [self setupStream];
    }
    return self;
}

- (void)dealloc
{
    [self teardownStream];
}

- (void)setupStream
{
    NSAssert(_xmppStream == nil, @"Method setupStream invoked multiple times");
    
    self.xmppStream = [[XMPPStream alloc] init];
    
    //Used to fetch correct account from XMPPStream in delegate methods especailly
    self.xmppStream.tag = @"unique_id_1";
    
    self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicyRequired;
    
#if !TARGET_IPHONE_SIMULATOR
    {
        // Want xmpp to run in the background?
        //
        // P.S. - The simulator doesn't support backgrounding yet.
        //        When you try to set the associated property on the simulator, it simply fails.
        //        And when you background an app on the simulator,
        //        it just queues network traffic til the app is foregrounded again.
        //        We are patiently waiting for a fix from Apple.
        //        If you do enableBackgroundingOnSocket on the simulator,
        //        you will simply see an error message from the xmpp stack when it fails to set the property.
        
        self.xmppStream.enableBackgroundingOnSocket = YES;
    }
#endif
    
    // Setup reconnect
    //
    // The XMPPReconnect module monitors for "accidental disconnections" and
    // automatically reconnects the stream for you.
    // There's a bunch more information in the XMPPReconnect header file.
    
    self.xmppReconnect = [[XMPPReconnect alloc] init];
    XMPPvCardCoreDataStorage* vCardStore = [[XMPPvCardCoreDataStorage alloc] initWithInMemoryStore];
    self.xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:vCardStore];
    
    // Setup capabilities
    //
    // The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
    // Basically, when other clients broadcast their presence on the network
    // they include information about what capabilities their client supports (audio, video, file transfer, etc).
    // But as you can imagine, this list starts to get pretty big.
    // This is where the hashing stuff comes into play.
    // Most people running the same version of the same client are going to have the same list of capabilities.
    // So the protocol defines a standardized way to hash the list of capabilities.
    // Clients then broadcast the tiny hash instead of the big list.
    // The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
    // and also persistently storing the hashes so lookups aren't needed in the future.
    //
    // Similarly to the roster, the storage of the module is abstracted.
    // You are strongly encouraged to persist caps information across sessions.
    //
    // The XMPPCapabilitiesCoreDataStorage is an ideal solution.
    // It can also be shared amongst multiple streams to further reduce hash lookups.
    
    self.xmppCapabilitiesStorage = [[XMPPCapabilitiesCoreDataStorage alloc] initWithInMemoryStore];
    self.xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:self.xmppCapabilitiesStorage];
    
    self.xmppCapabilities.autoFetchHashedCapabilities = YES;
    self.xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
    self.xmppDeliveryReceipts = [[XMPPMessageDeliveryReceipts alloc] initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [self.xmppDeliveryReceipts setAutoSendMessageDeliveryReceipts:YES];
    [self.xmppDeliveryReceipts setAutoSendMessageDeliveryRequests:YES];
    
    // Activate xmpp modules
    
    [self.xmppReconnect         activate:self.xmppStream];
    //[self.xmppRoster            activate:self.xmppStream];
    [self.xmppvCardTempModule   activate:self.xmppStream];
    //[self.xmppvCardAvatarModule activate:self.xmppStream];
    [self.xmppCapabilities      activate:self.xmppStream];
    [self.xmppDeliveryReceipts      activate:self.xmppStream];
    
    // Add ourself as a delegate to anything we may be interested in
    
    [self.xmppStream addDelegate:self delegateQueue:self.workQueue];
    //[self.xmppRoster addDelegate:self delegateQueue:self.workQueue];
    [self.xmppCapabilities addDelegate:self delegateQueue:self.workQueue];
    [self.xmppDeliveryReceipts addDelegate:self delegateQueue:self.workQueue];
    
    // Optional:
    //
    // Replace me with the proper domain and port.
    // The example below is setup for a typical google talk account.
    //
    // If you don't supply a hostName, then it will be automatically resolved using the JID (below).
    // For example, if you supply a JID like 'user@quack.com/rsrc'
    // then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
    // 
    // If you don't specify a hostPort, then the default (5222) will be used.
    
    [self.xmppStream setHostName:[RgManager ringmailHost]];
    [self.xmppStream setHostPort:5222];
}

- (void)teardownStream
{
    [_xmppStream removeDelegate:self];
    [_xmppCapabilities removeDelegate:self];
    
    [_xmppReconnect deactivate];
    [_xmppvCardTempModule deactivate];
    [_xmppCapabilities deactivate];
    [_xmppStream disconnect];
    
    _xmppStream = nil;
    _xmppReconnect = nil;
    _xmppvCardTempModule = nil;
    _xmppCapabilities = nil;
}

- (XMPPStream *)xmppStream
{
    if(!_xmppStream)
    {
        _xmppStream = [[XMPPStream alloc] init];
        _xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicyRequired;
    }
    return _xmppStream;
}

- (BOOL)isConnected
{
    return (! [_xmppStream isDisconnected]);
}

- (void)goOnline
{
    //self.connectionStatus = OTRProtocolConnectionStatusConnected;
    //[[NSNotificationCenter defaultCenter]
    // postNotificationName:kOTRProtocolLoginSuccess object:self];
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"available"]; // type="available" is implicit
    [[self xmppStream] sendElement:presence];
}

- (void)goOffline
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[self xmppStream] sendElement:presence];
}

- (void)authenticateWithStream:(XMPPStream *)stream
{
    NSError * error = nil;
    BOOL status = YES;
    status = [stream authenticateWithPassword:chatPassword error:&error];
}

- (BOOL)connectWithJID:(NSString*) myJID password:(NSString*)myPassword
{
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, myJID);
	self.replyTo = [myJID stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLUserAllowedCharacterSet];
    myJID = [RgManager addressToXMPP:myJID];
    self.JID = [XMPPJID jidWithString:myJID resource:@"RingMail"];
    
    //if (![self.JID.domain isEqualToString:self.xmppStream.myJID.domain]) {
    //    [self.xmppStream disconnect];
    //}
    
    [self.xmppStream setMyJID:self.JID];
    //DDLogInfo(@"myJID %@",myJID);
    if (![self.xmppStream isDisconnected]) {
        [self authenticateWithStream:self.xmppStream];
        return YES;
    }
    
    //
    // If you don't want to use the Settings view to set the JID,
    // uncomment the section below to hard code a JID and password.
    //
    // Replace me with the proper JID and password:
    //	myJID = @"user@gmail.com/xmppframework";
    //	myPassword = @"";
	
    self.chatPassword = myPassword;
    
    NSError* error = nil;
    if (![self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
    {
        //[self failedToConnect:error];
        
        NSLog(@"Error connecting: %@", error);
        
        return NO;
    }
    
    return YES;
}

- (void)disconnect
{
    //NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self goOffline];
    [self.xmppStream disconnect];
}

#pragma mark Chat actions

#pragma mark XMPPStream Delegate

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    settings[GCDAsyncSocketSSLProtocolVersionMin] = @(kTLSProtocol1);
    //settings[GCDAsyncSocketSSLCipherSuites] = [OTRUtilities cipherSuites];
    settings[GCDAsyncSocketManuallyEvaluateTrust] = @(YES);
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self authenticateWithStream:sender];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
    //self.connectionStatus = OTRProtocolConnectionStatusConnected;
    [self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
    //self.connectionStatus = OTRProtocolConnectionStatusDisconnected;
    //[self failedToConnect:[OTRXMPPError errorForXMLElement:error]];
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [iq elementID]);
    NSLog(@"%@", iq);
    return NO;
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender {
    //[self didRegisterNewAccount];
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)xmlError {
    
    //self.isRegisteringNewAccount = NO;
    //NSError * error = [OTRXMPPError errorForXMLElement:xmlError];
    //[self failedToRegisterNewAccount:error];
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)xmppMessage
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"%@", xmppMessage);
    if ([xmppMessage isMessageWithBody] && ![xmppMessage isErrorMessage])
    {
        /*NSString* uuid = [[xmppMessage attributeForName:@"id"] stringValue];
        NSNumber *session = [self dbUpdateMessageStatus:@"sent" forUUID:uuid];
		if (session)
		{
            NSDictionary *dict = @{
                                   @"session": session,
                                   @"uuid": uuid,
                                   @"status": @"sent",
                                   };
            [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextUpdate object:self userInfo:dict];
		}*/
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)xmppMessage
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"%@", xmppMessage);
    if (! [xmppMessage isErrorMessage])
    {
//        BOOL update = NO;
//        BOOL refresh = YES;
//        NSString *uuid = [[xmppMessage attributeForName:@"id"] stringValue];
        if ([xmppMessage isMessageWithBody])
        {
//            NSString *body = [[xmppMessage elementForName:@"body"] stringValue];
            NSString *from = [[xmppMessage attributeForName:@"from"] stringValue];
//            NSString *chatFrom = [RgManager addressFromXMPP:from];
//			NSString *origTo = [[xmppMessage attributeForName:@"original-to"] stringValue];
//            NSString *threadId = [[[xmppMessage attributeForName:@"uuid"] stringValue] lowercaseString];
            NSString *contactStr = [[xmppMessage attributeForName:@"contact"] stringValue];
			NSNumber *contactId = nil;
			if (contactStr != nil)
			{
				if ([contactStr isMatchedByRegex:@"^\\d+$"])
				{
					contactId = [NSNumber numberWithInt:[contactStr intValue]];
					if (! [RgManager hasContactId:contactId])
					{
						contactId = nil; // invalid contact id
					}
				}
			}
            NSDate *timestamp = [NSDate parse:[[xmppMessage attributeForName:@"timestamp"] stringValue]];
            if (timestamp == nil)
            {
                timestamp = [NSDate date];
            }
			
			
			/*
            NSXMLElement *attach = [xmppMessage elementForName:@"attachment"];
            NSXMLElement *jsonHolder = [xmppMessage JSONContainer];
            //NSLog(@"RingMail: Chat Attach: %@", attach);
            if (attach != nil)
            {
                refresh = NO;
                NSString *imageUrl = [[attach attributeForName:@"url"] stringValue];
                [self dbInsertMessage:session type:@"image/png" data:messageData uuid:uuid inbound:YES url:imageUrl];
                [[RgNetwork instance] downloadImage:imageUrl callback:^(NSURLSessionTask *operation, id responseObject) {
                    //NSLog(@"RingMail: Chat Download Complete: %@", responseObject);
                    NSData* imageData = responseObject;
                    [self dbUpdateMessageData:imageData forUUID:uuid key:@"msg_data"];
					// Create thumbnail
					//UIImage *orig = [UIImage imageWithData:imageData];
                    //UIImage *thumb = [orig scaleToFitSize:(CGSize){400, 400}];
            		//NSData *imgThumb = UIImagePNGRepresentation(thumb);
                    //[self dbUpdateMessageData:imgThumb forUUID:uuid key:@"msg_thumbnail"];
                    NSDictionary *dict = @{
                       @"session": session,
                       @"uuid": uuid,
                    };
                    [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextUpdate object:self userInfo:dict];
                }];
            }
            else if (jsonHolder != nil)
            {
                NSData *jsonData = [jsonHolder JSONContainerData];
                NSError *jsonErr = nil;
                NSDictionary *jsonInfo = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonErr];
                NSString *jsonType = [jsonInfo objectForKey:@"type"];
                if ([jsonType isEqualToString:@"ping"] && [jsonInfo objectForKey:@"reply"])
                {
                    NSString* replyUUID = [jsonInfo objectForKey:@"reply"];
                    NSMutableDictionary* newData = [NSMutableDictionary dictionaryWithDictionary:jsonInfo];
                    [newData setObject:[NSNumber numberWithBool:1] forKey:@"answered"];
                    [newData removeObjectForKey:@"reply"];
                    NSError *jsonErr = nil;
                    [self dbUpdateMessageData:[NSJSONSerialization dataWithJSONObject:newData options:0 error:&jsonErr] forUUID:replyUUID key:@"msg_data"];
                    update = YES;
                    uuid = replyUUID;
                }
                if (! update)
                {
                    [messageData setObject:jsonData forKey:@"data"];
                    [self dbInsertMessage:session type:@"application/json" data:messageData uuid:[[xmppMessage attributeForName:@"id"] stringValue] inbound:YES url:nil];
                }
            }
            else
            {
                [self dbInsertMessage:session type:@"text/plain" data:messageData uuid:[[xmppMessage attributeForName:@"id"] stringValue] inbound:YES url:nil];
            }
			*/
            
            //[RgManager startMessageMD5]; // check if a push for a new chat arrived first
            
            // Should not happen because we log out of chat when we enter the background now
            /*if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
            {
                // Create a new notification
                UILocalNotification *notif = [[UILocalNotification alloc] init];
                if (notif) {
                    notif.repeatInterval = 0;
                    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8) {
                        notif.category = @"incoming_msg";
                    }
                    notif.alertBody = [NSString stringWithFormat:@"%@: %@", chatFrom, body];
                    notif.alertAction = NSLocalizedString(@"Show", nil);
                    notif.soundName = @"msg.caf";
                    notif.userInfo = @{ @"from" : chatFrom };
                    
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
                }
            }*/
			
			/*
            NSDictionary *dict = @{
                @"session": session,
                @"uuid": uuid,
            };
            
            if (update)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextUpdate object:self userInfo:dict];
            }
            else if (refresh)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextReceived object:self userInfo:dict];
            }
            */
			
            //NSLog(@"NEW CHAT FROM %@: %@\nLog: %@", chatFrom, body, [self dbGetMessages:chatFrom]);
        }
        else if ([xmppMessage isTo:self.JID options:XMPPJIDCompareUser])
        {
            NSXMLElement *delivered = [xmppMessage elementForName:@"received" xmlns:@"urn:xmpp:receipts"];
            if (delivered != nil) // Delivery receipt
            {
                //NSString* uuid = [[delivered attributeForName:@"id"] stringValue];
                /*NSNumber *session = [self dbUpdateMessageStatus:@"delivered" forUUID:uuid];
				if (session != nil)
				{
                    NSDictionary *dict = @{
                                           @"session": session,
                                           @"uuid": uuid,
                                           @"status": @"delivered",
                                           };
                    [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextUpdate object:self userInfo:dict];
				}*/
            }
        }
    }
    else // Is error message
    {
        NSXMLElement *delivered = [xmppMessage elementForName:@"delivered" xmlns:@"urn:xmpp:receipts"];
        if (delivered == nil) // Ignore double errors from delivered receipts
        {
            NSError *error = [xmppMessage errorMessage];
            NSLog(@"XMPP Error Code: %tu", [error code]);
            if ([error code] == 503)
            {
                NSLog(@"XMPP Error: Bad RingMail Address");
			}
            else
            {
                NSLog(@"XMPP Error: %@", error);
            }
        }
    }

}
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"%@: %@ - %@\nType: %@\nShow: %@\nStatus: %@", THIS_FILE, THIS_METHOD, [presence from], [presence type], [presence show],[presence status]);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL))completionHandler
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
    completionHandler(YES);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    if ([message.elementID length]) {
        /*[self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [OTRMessage enumerateMessagesWithMessageId:message.elementID transaction:transaction usingBlock:^(OTRMessage *message, BOOL *stop) {
                message.error = error;
                [message saveWithTransaction:transaction];
                *stop = YES;
            }];
        }];*/
    }
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendPresence:(XMPPPresence *)presence error:(NSError *)error
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    NSLog(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error);
    //self.connectionStatus = OTRProtocolConnectionStatusDisconnected;
    /*if (!self.isXmppConnected)
    {
        DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
        [self failedToConnect:error];
    }
    else {
        [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            NSArray *allBuddies = [self.account allBuddiesWithTransaction:transaction];
            [allBuddies enumerateObjectsUsingBlock:^(OTRXMPPBuddy *buddy, NSUInteger idx, BOOL *stop) {
                buddy.status = OTRBuddyStatusOffline;
                buddy.statusMessage = nil;
                [transaction setObject:buddy forKey:buddy.uniqueId inCollection:[OTRXMPPBuddy collection]];
            }];
            
        }];
    }
    self.isXmppConnected = NO;*/
}

@end
