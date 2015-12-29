//
//  RgChatManager.m
//  ringmail
//
//  Created by Mike Frager on 9/1/15.
//
//

#import "RgChatManager.h"
#import "NSString+MD5.h"
#import "NSXMLElement+XMPP.h"
#import "NoteSQL.h"

#define THIS_FILE   @"RgChatManager"
#define THIS_METHOD NSStringFromSelector(_cmd)

@implementation RgChatManager

@synthesize chatPassword;

- (id)init
{
    if (self = [super init])
    {
        NSString *queueLabel = [NSString stringWithFormat:@"%@.work.%@", [self class], self];
        self.workQueue = dispatch_queue_create([queueLabel UTF8String], 0);
        self.chatPassword = @"";
        [self setupDatabase];
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

- (void)authenticateWithStream:(XMPPStream *)stream {
    NSError * error = nil;
    BOOL status = YES;
    status = [stream authenticateWithPassword:chatPassword error:&error];
}

- (BOOL)connectWithJID:(NSString*) myJID password:(NSString*)myPassword
{
    NSLog(@"RingMail Chat Connect: %@", myJID);
    //  NSLog(@"RingMail Chat Password: %@", myPassword);
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
    //NSLog(@"RingMail: Chat - Request Disconnect");
    [self goOffline];    
    [self.xmppStream disconnect];
}

#pragma mark Chat actions

- (NSString*)sendMessageTo:(NSString*)to body:(NSString*)body
{
    return [self sendMessageTo:to body:body reply:nil];
}

- (NSString*)sendMessageTo:(NSString*)to body:(NSString*)text reply:(NSString*)reply
{
    NSString *msgTo = [RgManager addressToXMPP:to];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:text];
    NSString *messageID = [[self xmppStream] generateUUID];
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:msgTo];
    if (reply)
    {
       [message addAttributeWithName:@"reply" stringValue:reply];
    }
    [message addChild:body];
    
    [self dbInsertMessage:to type:@"text/plain" data:text uuid:messageID inbound:NO url:nil];
    [[self xmppStream] sendElement:message];
    return messageID;
}

- (void)sendMessageTo:(NSString*)to image:(UIImage*)image
{
    NSString *msgTo = [RgManager addressToXMPP:to];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:@"Picture"];
    NSString *messageID = [[self xmppStream] generateUUID];
    __block NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:msgTo];
    [message addChild:body];
    
    // TODO: send images a different way like upload/download
    NSString *imageID = [[self xmppStream] generateUUID];
   
    NSData *imageData = UIImagePNGRepresentation(image);
    [self dbInsertMessage:to type:@"image/png" data:imageData uuid:messageID inbound:NO url:nil];
    //NSLog(@"RingMail: Insert Image Message");
    [[RgNetwork instance] uploadImage:imageData uuid:imageID callback:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary* res = responseObject;
        //NSLog(@"RingMail - Chat Upload Success: %@", res);
        NSString *ok = [res objectForKey:@"result"];
        if ([ok isEqualToString:@"ok"])
        {
            NSXMLElement *imageAttach = [NSXMLElement elementWithName:@"attachment"];
            [imageAttach addAttributeWithName:@"type" stringValue:@"image/png"];
            [imageAttach addAttributeWithName:@"id" stringValue:imageID];
            [imageAttach addAttributeWithName:@"url" stringValue:[res objectForKey:@"url"]];
            [message addChild:imageAttach];
            [[self xmppStream] sendElement:message];
        }
    }];
}

- (NSString *)sendPingTo:(NSString*)to reply:(NSString*)reply
{
    NSString *msgTo = [RgManager addressToXMPP:to];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:@"Ping"];
    NSString *messageID = [[self xmppStream] generateUUID];
    __block NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:msgTo];
    [message addChild:body];
    
    //[self dbInsertMessage:to type:@"image/png" data:imageData uuid:messageID inbound:NO url:nil];
    //NSLog(@"RingMail: Insert Image Message");
    
    NSMutableDictionary *pingData = [NSMutableDictionary dictionaryWithDictionary:@{
          @"type": @"ping",
          @"body": @"Ping",
    }];
    if (reply)
    {
        [body setStringValue:@"Ping"];
        [pingData setObject:@"Ping" forKey:@"body"];
        [pingData setObject:reply forKey:@"reply"];
    }
    else
    {
        NSError *jsonErr = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:pingData options:0 error:&jsonErr];
        [self dbInsertMessage:to type:@"application/json" data:jsonData uuid:messageID inbound:NO url:nil];
    }
    
    [message addJSONContainerWithObject:pingData];
    [[self xmppStream] sendElement:message];
    return messageID;
}

- (NSString *)sendQuestionTo:(NSString*)to question:(NSString*)question answers:(NSArray*)answers
{
    NSDictionary *questionInfo = @{
                                   @"type": @"question",
                                   @"body": question,
                                   @"answers": answers,
                                   };
    
    NSString *msgTo = [RgManager addressToXMPP:to];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:question];
    NSString *messageID = [[self xmppStream] generateUUID];
    __block NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:msgTo];
    [message addChild:body];
    
    //[self dbInsertMessage:to type:@"image/png" data:imageData uuid:messageID inbound:NO url:nil];
    //NSLog(@"RingMail: Insert Image Message");
    
    [message addJSONContainerWithObject:questionInfo];
    NSError *jsonErr = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:questionInfo options:0 error:&jsonErr];
    [self dbInsertMessage:to type:@"application/json" data:jsonData uuid:messageID inbound:NO url:nil];
    
    [[self xmppStream] sendElement:message];
    return messageID;
}

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
        NSString* uuid = [[xmppMessage attributeForName:@"id"] stringValue];
        [self dbUpdateMessageStatus:@"sent" forUUID:uuid];
        NSString *to = [[xmppMessage attributeForName:@"to"] stringValue];
        NSString *chatTo = [RgManager addressFromXMPP:to];
        NSDictionary *dict = @{
                               @"tag": chatTo,
                               @"uuid": uuid,
                               @"status": @"sent",
                               };
        [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextUpdate object:self userInfo:dict];
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)xmppMessage
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"%@", xmppMessage);
    if (! [xmppMessage isErrorMessage])
    {
        BOOL update = NO;
        __block NSString *uuid = [[xmppMessage attributeForName:@"id"] stringValue];
        if ([xmppMessage isMessageWithBody])
        {
            NSString *body = [[xmppMessage elementForName:@"body"] stringValue];
            NSString *from = [[xmppMessage attributeForName:@"from"] stringValue];
            
            __block NSString *chatFrom = [RgManager addressFromXMPP:from];
            
            NSXMLElement *attach = [xmppMessage elementForName:@"attachment"];
            NSXMLElement *jsonHolder = [xmppMessage JSONContainer];
            //NSLog(@"RingMail: Chat Attach: %@", attach);
            if (attach != nil)
            {
                NSString *imageUrl = [[attach attributeForName:@"url"] stringValue];
                [self dbInsertMessage:chatFrom type:@"image/png" data:nil uuid:uuid inbound:YES url:imageUrl];
                [[RgNetwork instance] downloadImage:imageUrl callback:^(AFHTTPRequestOperation *operation, id responseObject) {
                    //NSLog(@"RingMail: Chat Download Complete: %@", responseObject);
                    NSData* imageData = responseObject;
                    [self dbUpdateMessageData:imageData forUUID:uuid];
                    NSDictionary *dict = @{
                       @"tag": chatFrom,
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
                    [self dbUpdateMessageData:[NSJSONSerialization dataWithJSONObject:newData options:0 error:&jsonErr] forUUID:replyUUID];
                    update = YES;
                    uuid = replyUUID;
                }
                if (! update)
                {
                    [self dbInsertMessage:chatFrom type:@"application/json" data:jsonData uuid:[[xmppMessage attributeForName:@"id"] stringValue] inbound:YES url:nil];
                }
            }
            else
            {
                [self dbInsertMessage:chatFrom type:@"text/plain" data:body uuid:[[xmppMessage attributeForName:@"id"] stringValue] inbound:YES url:nil];
            }
            
            [RgManager startMessageMD5]; // check if a push for a new chat arrived first
            
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
            
            NSDictionary *dict = @{
                @"tag": chatFrom,
                @"uuid": uuid,
            };
            
            if (update)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextUpdate object:self userInfo:dict];
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextReceived object:self userInfo:dict];
            }
            
            //NSLog(@"NEW CHAT FROM %@: %@\nLog: %@", chatFrom, body, [self dbGetMessages:chatFrom]);
        }
        else if ([xmppMessage isTo:self.JID])
        {
            NSXMLElement *received = [xmppMessage elementForName:@"received" xmlns:@"urn:xmpp:receipts"];
            if (received != nil)
            {
                NSString* uuid = [[received attributeForName:@"id"] stringValue];
                [self dbUpdateMessageStatus:@"received" forUUID:uuid];
                NSString *from = [[xmppMessage attributeForName:@"from"] stringValue];
                NSString *chatFrom = [RgManager addressFromXMPP:from];
                NSDictionary *dict = @{
                                       @"tag": chatFrom,
                                       @"uuid": uuid,
                                       @"status": @"received",
                                       };
                [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextUpdate object:self userInfo:dict];
            }
        }
    }
    else // Is error message
    {
        NSXMLElement *received = [xmppMessage elementForName:@"received" xmlns:@"urn:xmpp:receipts"];
        if (received == nil) // Ignore double errors from received receipts
        {
            NSError *error = [xmppMessage errorMessage];
            NSLog(@"XMPP Error Code: %tu", [error code]);
            if ([error code] == 503)
            {
                NSLog(@"XMPP Error: Bad RingMail Address");
                NSString *from = [[xmppMessage attributeForName:@"from"] stringValue];
                NSString *chatFrom = [RgManager addressFromXMPP:from];
                
                // Delete the chatroom
                [self dbDeleteSessionID:chatFrom];
                
                NSDictionary *dict = @{
                                       @"tag": chatFrom,
                                       @"error": @"Address not registered",
                };
                [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextReceived object:self userInfo:dict];
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

#pragma mark Chat database manager

- (FMDatabaseQueue *)database
{
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#ifdef DEBUG
    NSString *dbPath = [docsPath stringByAppendingPathComponent:@"ringmail_dev"];
#else
    NSString *dbPath = [docsPath stringByAppendingPathComponent:@"ringmail"];
#endif
    dbPath = [dbPath stringByAppendingString:@"_v1.1.8.db"];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    return queue;
}

- (void)setupDatabase
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        NSArray *setup = [NSArray arrayWithObjects:
                                //@"DROP TABLE session;",
                                @"CREATE TABLE IF NOT EXISTS session (session_tag TEXT NOT NULL, unread INT NOT NULL DEFAULT 0, session_md5 TEXT NOT NULL);",
                                @"CREATE UNIQUE INDEX IF NOT EXISTS session_tag_1 ON session (session_tag);",
                                @"CREATE INDEX IF NOT EXISTS session_md5_1 ON session (session_md5);",
                                //@"DROP TABLE chat;",
                                @"CREATE TABLE IF NOT EXISTS chat (session_id INTEGER NOT NULL, msg_body TEXT NOT NULL, msg_time TEXT NOT NULL, msg_inbound INTEGER, msg_uuid TEXT NOT NULL, msg_status TEXT NOT NULL DEFAULT '', msg_data BLOB DEFAULT NULL, msg_type TEXT DEFAULT 'text/plain', msg_url TEXT DEFAULT NULL);",
                                @"CREATE INDEX IF NOT EXISTS session_id_1 ON chat (session_id);",
                                @"CREATE INDEX IF NOT EXISTS msg_uuid_1 ON chat (msg_uuid);",
                                //@"DROP TABLE call;",
                                @"CREATE TABLE IF NOT EXISTS calls (call_duration TEXT NULL DEFAULT NULL, call_inbound INT NOT NULL DEFAULT 0, call_sip text NOT NULL, call_state INT NOT NULL DEFAULT 0, call_time text NOT NULL, session_id INT NOT NULL DEFAULT 0);",
                                @"CREATE INDEX IF NOT EXISTS call_sip_1 ON calls (call_sip)",
                          nil];
        for (NSString *sql in setup)
        {
            [db executeStatements:sql];
            if ([db hadError])
            {
                NSLog(@"SQL Error: %@\nSQL:\n%@", [db lastErrorMessage], sql);
            }
        }
    }];
    [dbq close];
    NSLog(@"SQL Database Ready");
}

- (void)dropTables
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        NSArray *setup = [NSArray arrayWithObjects:
                                @"DROP TABLE session;",
                                @"DROP TABLE chat;",
                                @"DROP TABLE calls;",
                          nil];
        for (NSString *sql in setup)
        {
            [db executeStatements:sql];
            if ([db hadError])
            {
                NSLog(@"SQL Error: %@\nSQL:\n%@", [db lastErrorMessage], sql);
            }
        }
    }];
    [dbq close];
    [self setupDatabase]; // Set it up again
    NSLog(@"SQL Database Ready");
}

- (NSNumber *)dbGetSessionID:(NSString *)from
{
    //NSLog(@"RingMail: Chat - Session ID:(%@)", from);
    FMDatabaseQueue *dbq = [self database];
    __block NSNumber* result;
    [dbq inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT rowid FROM session WHERE session_tag = ?", from];
        if ([rs next])
        {
            result = [NSNumber numberWithLong:[rs longForColumnIndex:0]];
        }
        else
        {
            [db executeUpdate:@"INSERT INTO session (session_tag, session_md5, unread) VALUES (?, ?, 0);", from, [from md5HexDigest]];
            result = [NSNumber numberWithLongLong:[db lastInsertRowId]];
        }
        [rs close];
    }];
    [dbq close];
    return result;
}

- (void)dbDeleteSessionID:(NSString *)from
{
    //NSLog(@"RingMail: Chat Delete - Session ID:(%@)", from);
    FMDatabaseQueue *dbq = [self database];
    NSNumber* session = [self dbGetSessionID:from];
    [dbq inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM chat WHERE session_id = ?;", session];
        [db executeUpdate:@"DELETE FROM call WHERE session_id = ?;", session];
        [db executeUpdate:@"DELETE FROM session WHERE session_tag = ?;", from];
    }];
    [dbq close];
}

- (void)dbInsertMessage:(NSString *)from type:(NSString *)type data:(NSObject*)data uuid:(NSString*)uuid inbound:(BOOL)inbound url:(NSString*)msgUrl
{
    FMDatabaseQueue *dbq = [self database];
    NSNumber* session = [self dbGetSessionID:from];
    NSString* status = (inbound) ? @"" : @"sending";
    NSString* body = @"";
    NSData* msgData = nil;
    if ([type isEqualToString:@"text/plain"])
    {
        body = (NSString*)data;
    }
    else if ([type isEqualToString:@"image/png"])
    {
        msgData = (NSData*)data;
    }
    else if ([type isEqualToString:@"application/json"])
    {
        msgData = (NSData*)data;
    }
    else
    {
        NSLog(@"RingMail Error: Invalid message type: '%@'", type);
    }
    [dbq inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"INSERT INTO chat (session_id, msg_body, msg_time, msg_inbound, msg_uuid, msg_status, msg_type, msg_data, msg_url) VALUES (?, ?, datetime('now'), ?, ?, ?, ?, ?, ?);", session, body, [NSNumber numberWithBool:inbound], uuid, status, type, msgData, msgUrl];
        if (inbound)
        {
            [db executeUpdate:@"UPDATE session SET unread = unread + 1 WHERE session_tag = ?", from];
        }
    }];
    [dbq close];
}

- (void)dbUpdateMessageStatus:(NSString*)status forUUID:(NSString*)uuid
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE chat SET msg_status = ? WHERE msg_uuid = ?", status, uuid];
    }];
    [dbq close];
}

- (void)dbUpdateMessageData:(NSData*)data forUUID:(NSString*)uuid
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE chat SET msg_data = ? WHERE msg_uuid = ?", data, uuid];
    }];
    [dbq close];
}

- (NSArray *)dbGetSessions
{
    FMDatabaseQueue *dbq = [self database];
    __block NSMutableArray *result = [NSMutableArray array];
    [dbq inDatabase:^(FMDatabase *db) {
        /*FMResultSet *r1 = [db executeQuery:@"SELECT * FROM session;"];
        while ([r1 next])
        {
            NSLog(@"%@", [r1 resultDictionary]);
        }
        [r1 close];*/
        
        /*FMResultSet *r2 = [db executeQuery:@"SELECT * FROM calls;"];
        while ([r2 next])
        {
            NSLog(@"%@", [r2 resultDictionary]);
        }
        [r2 close];*/
        
        NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
        NSArray *res1 = [ndb get:@{
           @"table":@"calls",
           @"select":@[@"oid",@"call_sip",@"session_id",@"call_state"],
        }];
        NSLog(@"Note DB Query: %@", res1);
        for (id i in res1)
        {
            NoteRow* r = [ndb row:@"calls" id:[i objectForKey:@"rowid"]];
            NSDictionary* rd = [r data];
            NSLog(@"Note DB Row: %@", rd);
        }
        
        FMResultSet *rs = [db executeQuery:@"SELECT session_tag, unread, (SELECT msg_body FROM chat WHERE chat.session_id=session.rowid AND msg_type = 'text/plain' ORDER BY rowid DESC LIMIT 1) as last_message, (SELECT STRFTIME('%s', msg_time) FROM chat WHERE chat.session_id=session.rowid AND msg_type = 'text/plain' ORDER BY rowid DESC LIMIT 1) as last_time, (SELECT call_sip FROM calls WHERE calls.session_id=session.rowid ORDER BY rowid DESC LIMIT 1) as call_id, (SELECT STRFTIME('%s', call_time) FROM calls WHERE calls.session_id=session.rowid ORDER BY rowid DESC LIMIT 1) as call_time FROM session ORDER BY rowid DESC"];
        while ([rs next])
        {
            NSLog(@"RingMail Chat Result Set: %@", [rs resultDictionary]);
            NSString* last = [rs stringForColumnIndex:2];
            if (last == nil)
            {
                last = @"";
            }
            [result addObject:[NSArray arrayWithObjects:
                               [rs stringForColumnIndex:0],
                               [rs objectForColumnIndex:1],
                               last,
                               [rs objectForColumnIndex:3], // Message timestamp
                               [rs objectForColumnIndex:4], // Call timestamp
                               [rs objectForColumnIndex:5],
                               nil]];
        }
        [rs close];
    }];
    NSLog(@"RingMail dbGetSession: %@", result);
    [dbq close];
    return result;
}

- (NSArray *)dbGetMessages:(NSString *)from
{
    return [self dbGetMessages:(NSString *)from uuid:nil];
}

- (NSArray *)dbGetMessages:(NSString *)from uuid:(NSString*)uuid;
{
    FMDatabaseQueue *dbq = [self database];
    NSNumber* session = [self dbGetSessionID:from];
    __block NSMutableArray *result = [NSMutableArray array];
    [dbq inDatabase:^(FMDatabase *db) {
        FMResultSet *rs;
        if (uuid)
        {
            rs = [db executeQuery:@"SELECT rowid, msg_body, STRFTIME('%s', msg_time), msg_inbound, msg_type, msg_uuid FROM chat WHERE msg_uuid = ? ORDER BY rowid DESC LIMIT 50", uuid];
        }
        else
        {
            rs = [db executeQuery:@"SELECT rowid, msg_body, STRFTIME('%s', msg_time), msg_inbound, msg_type, msg_uuid FROM chat WHERE session_id = ? ORDER BY rowid DESC LIMIT 50", session];
        }
        while ([rs next])
        {
            [result addObject:@{
                @"id": [rs objectForColumnIndex:0],
                @"body": [rs stringForColumnIndex:1],
                @"time": [NSDate dateWithTimeIntervalSince1970:[rs doubleForColumnIndex:2]],
                @"direction": ([rs boolForColumnIndex:3]) ? @"inbound" : @"outbound",
                @"type": [rs stringForColumnIndex:4],
                @"uuid": [rs stringForColumnIndex:5],
            }];
        }
        [rs close];
        [db executeUpdate:@"UPDATE session SET unread = 0 WHERE session_tag = ?", from];
    }];
    [dbq close];
    result = [NSMutableArray arrayWithArray:[[result reverseObjectEnumerator] allObjects]];
    return result;
}

- (NSNumber *)dbGetSessionUnread
{
    FMDatabaseQueue *dbq = [self database];
    __block NSNumber* result;
    [dbq inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT SUM(unread) FROM session"];
        if ([rs next])
        {
            result = [NSNumber numberWithLong:[rs longForColumnIndex:0]];
        }
        else
        {
            result = [NSNumber numberWithInt:0];
        }
        [rs close];
    }];
    [dbq close];
    return result;
}

- (NSData *)dbGetMessageData:(NSNumber*)msgId
{
    FMDatabaseQueue *dbq = [self database];
    __block NSData* result = nil;
    [dbq inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT msg_data FROM chat WHERE rowid = ?", msgId];
        if ([rs next])
        {
            result = [rs dataForColumnIndex:0];
        }
        [rs close];
    }];
    [dbq close];
    return result;
}

- (NSData *)dbGetMessageDataByUUID:(NSString*)uuid
{
    FMDatabaseQueue *dbq = [self database];
    __block NSData* result = nil;
    [dbq inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT msg_data FROM chat WHERE msg_uuid = ?", uuid];
        if ([rs next])
        {
            result = [rs dataForColumnIndex:0];
        }
        [rs close];
    }];
    [dbq close];
    return result;
}

- (NSString *)dbGetMessageStatusByUUID:(NSString*)uuid
{
    FMDatabaseQueue *dbq = [self database];
    __block NSString* result = nil;
    [dbq inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT msg_status FROM chat WHERE msg_uuid = ?", uuid];
        if ([rs next])
        {
            result = [rs stringForColumnIndex:0];
        }
        [rs close];
    }];
    [dbq close];
    return result;
}

- (NSString *)dbGetSessionByMD5:(NSString*)lookup
{
    NSLog(@"RingMail: Chat - Session MD5:(%@)", lookup);
    if (! [lookup isMatchedByRegex:@"^[A-Fa-f0-9]{6,32}$"])
    {
        return @"";
    }
    lookup = [lookup stringByAppendingString:@"%"];
    FMDatabaseQueue *dbq = [self database];
    __block NSString* result = @"";
    [dbq inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT session_tag FROM session WHERE session_md5 LIKE ?", lookup];
        if ([rs next])
        {
            result = [rs stringForColumnIndex:0];
        }
        [rs close];
    }];
    [dbq close];
    return result;
}

- (void)dbInsertCall:(NSDictionary*)callData
{
    FMDatabaseQueue *dbq = [self database];
    NSNumber* session = [self dbGetSessionID:[callData objectForKey:@"address"]];
       [dbq inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"INSERT INTO calls (session_id, call_sip, call_state, call_inbound, call_time) VALUES (?, ?, ?, ?, datetime('now'));",
            session,
            [callData objectForKey:@"sip"],
            [callData objectForKey:@"state"],
            [callData objectForKey:@"inbound"]
        ];
    }];
    [dbq close];
}

- (void)dbUpdateCall:(NSDictionary*)callData
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE calls SET call_state = ? WHERE call_sip = ?",
            [callData objectForKey:@"state"],
            [callData objectForKey:@"sip"]
        ];
    }];
    [dbq close];
}

@end
