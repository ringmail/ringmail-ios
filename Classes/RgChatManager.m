//
//  RgChatManager.m
//  ringmail
//
//  Created by Mike Frager on 9/1/15.
//
//

#import "RgChatManager.h"
#import "RgNetwork.h"
#import "NSString+MD5.h"
#import "NSXMLElement+XMPP.h"
#import "NoteSQL.h"
#import <ObjectiveSugar/ObjectiveSugar.h>

#define THIS_FILE   @"RgChatManager"
#define THIS_METHOD NSStringFromSelector(_cmd)

@implementation RgChatManager

@synthesize chatPassword;
@synthesize databaseQueue;

- (id)init
{
    if (self = [super init])
    {
        NSString *queueLabel = [NSString stringWithFormat:@"%@.work.%@", [self class], self];
        self.workQueue = dispatch_queue_create([queueLabel UTF8String], 0);
        self.chatPassword = @"";
        self.replyTo = @"";
        self.databaseQueue = nil;
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
    //NSLog(@"RingMail: Chat - Request Disconnect");
    [self goOffline];    
    [self.xmppStream disconnect];
}

#pragma mark Chat actions

- (NSString*)sendMessageTo:(NSString*)to body:(NSString*)body contact:(NSNumber*)contact
{
    return [self sendMessageTo:to body:body reply:nil contact:contact];
}

- (NSString*)sendMessageTo:(NSString*)to body:(NSString*)text reply:(NSString*)reply contact:(NSNumber*)contact
{
	NSLog(@"Send Message To: %@", to);
    __block NSDate *now = [NSDate date];
    __block NSString *messageID = [[self xmppStream] generateUUID];
    NSMutableDictionary *messageData = [NSMutableDictionary dictionary];
    [messageData setObject:text forKey:@"body"];
    [messageData setObject:now forKey:@"timestamp"];
  	NSNumber *session = [self dbGetSessionID:to contact:contact];
    [self dbInsertMessage:session type:@"text/plain" data:messageData uuid:messageID inbound:NO url:nil];
    NSString *msgTo = [RgManager addressToXMPP:to];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:text];
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"timestamp" stringValue:[now strftime]];
    [message addAttributeWithName:@"to" stringValue:msgTo];
	if (contact != nil)
	{
		[message addAttributeWithName:@"reply-to" stringValue:self.replyTo];
	}
    if (reply)
    {
       [message addAttributeWithName:@"reply" stringValue:reply];
    }
    [message addChild:body];
    [[self xmppStream] sendElement:message];
    return messageID;
}

- (void)sendMessageTo:(NSString*)to image:(UIImage*)image contact:(NSNumber*)contact
{
    NSDate *now = [NSDate date];
    NSString *msgTo = [RgManager addressToXMPP:to];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:@"Picture"];
    NSString *messageID = [[self xmppStream] generateUUID];
    __block NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"timestamp" stringValue:[now strftime]];
    [message addAttributeWithName:@"to" stringValue:msgTo];
    [message addChild:body];
    
    // TODO: send images a different way like upload/download
    NSString *imageID = [[self xmppStream] generateUUID];
   
    NSData *imageData = UIImagePNGRepresentation(image);
    NSMutableDictionary *messageData = [NSMutableDictionary dictionary];
    [messageData setObject:imageData forKey:@"image"];
    [messageData setObject:now forKey:@"timestamp"];
    
	NSNumber *session = [self dbGetSessionID:to contact:contact];
    [self dbInsertMessage:session type:@"image/png" data:messageData uuid:messageID inbound:NO url:nil];
    //NSLog(@"RingMail: Insert Image Message");
    [[RgNetwork instance] uploadImage:imageData uuid:imageID callback:^(NSURLSessionTask *operation, id responseObject) {
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

/*- (NSString *)sendPingTo:(NSString*)to reply:(NSString*)reply
{
    NSDate *now = [NSDate date];
    NSString *msgTo = [RgManager addressToXMPP:to];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:@"Ping"];
    NSString *messageID = [[self xmppStream] generateUUID];
    __block NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"timestamp" stringValue:[now strftime]];
    [message addAttributeWithName:@"to" stringValue:msgTo];
    [message addChild:body];
    
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
        NSMutableDictionary *messageData = [NSMutableDictionary dictionary];
        [messageData setObject:jsonData forKey:@"data"];
        [messageData setObject:now forKey:@"timestamp"];
        [self dbInsertMessage:to type:@"application/json" data:messageData uuid:messageID inbound:NO url:nil];
    }
    
    [message addJSONContainerWithObject:pingData];
    [[self xmppStream] sendElement:message];
    return messageID;
}*/

/*- (NSString *)sendQuestionTo:(NSString*)to question:(NSString*)question answers:(NSArray*)answers
{
    NSDate *now = [NSDate date];
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
    [message addAttributeWithName:@"timestamp" stringValue:[[NSDate date] strftime]];
    [message addAttributeWithName:@"to" stringValue:msgTo];
    [message addChild:body];
    
    [message addJSONContainerWithObject:questionInfo];
    NSError *jsonErr = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:questionInfo options:0 error:&jsonErr];
    NSMutableDictionary *messageData = [NSMutableDictionary dictionary];
    [messageData setObject:jsonData forKey:@"data"];
    [messageData setObject:now forKey:@"timestamp"];
    
    [self dbInsertMessage:to type:@"application/json" data:messageData uuid:messageID inbound:NO url:nil];
    
    [[self xmppStream] sendElement:message];
    return messageID;
}*/

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
        NSNumber *session = [self dbUpdateMessageStatus:@"sent" forUUID:uuid];
		if (session)
		{
            NSDictionary *dict = @{
                                   @"session": session,
                                   @"uuid": uuid,
                                   @"status": @"sent",
                                   };
            [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextUpdate object:self userInfo:dict];
		}
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
            NSString *contactStr = [[xmppMessage attributeForName:@"contact-id"] stringValue];
			NSNumber *contact = nil;
			if (contactStr != nil)
			{
				if ([contactStr isMatchedByRegex:@"^\\d+$"])
				{
					contact = [NSNumber numberWithInt:[contactStr intValue]];
					if (! [RgManager hasContactId:contact])
					{
						contact = nil; // invalid contact id
					}
				}
			}
            NSMutableDictionary *messageData = [NSMutableDictionary dictionary];
            NSDate *timestamp = [NSDate parse:[[xmppMessage attributeForName:@"timestamp"] stringValue]];
            if (timestamp == nil)
            {
                timestamp = [NSDate date];
            }
            [messageData setObject:timestamp forKey:@"timestamp"];
            [messageData setObject:body forKey:@"body"];
			
            __block NSString *chatFrom = [RgManager addressFromXMPP:from];
			__block NSNumber *session = [self dbGetSessionID:chatFrom contact:contact];
			
            NSXMLElement *attach = [xmppMessage elementForName:@"attachment"];
            NSXMLElement *jsonHolder = [xmppMessage JSONContainer];
            //NSLog(@"RingMail: Chat Attach: %@", attach);
            if (attach != nil)
            {
                NSString *imageUrl = [[attach attributeForName:@"url"] stringValue];
                [self dbInsertMessage:session type:@"image/png" data:messageData uuid:uuid inbound:YES url:imageUrl];
                [[RgNetwork instance] downloadImage:imageUrl callback:^(NSURLSessionTask *operation, id responseObject) {
                    //NSLog(@"RingMail: Chat Download Complete: %@", responseObject);
                    NSData* imageData = responseObject;
                    [self dbUpdateMessageData:imageData forUUID:uuid];
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
                    [self dbUpdateMessageData:[NSJSONSerialization dataWithJSONObject:newData options:0 error:&jsonErr] forUUID:replyUUID];
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
                @"session": session,
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
        else if ([xmppMessage isTo:self.JID options:XMPPJIDCompareUser])
        {
            NSXMLElement *delivered = [xmppMessage elementForName:@"received" xmlns:@"urn:xmpp:receipts"];
            if (delivered != nil)
            {
                NSString* uuid = [[delivered attributeForName:@"id"] stringValue];
                NSNumber *session = [self dbUpdateMessageStatus:@"delivered" forUUID:uuid];
				if (session != nil)
				{
                    NSDictionary *dict = @{
                                           @"session": session,
                                           @"uuid": uuid,
                                           @"status": @"delivered",
                                           };
                    [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextUpdate object:self userInfo:dict];
				}
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
                NSString *from = [[xmppMessage attributeForName:@"from"] stringValue];
                NSString *chatFrom = [RgManager addressFromXMPP:from];
                
                // TODO: Delete the chatroom
				NSNumber *session = [self dbGetSessionID:chatFrom contact:nil];
                //[self dbDeleteSessionID:session];
                
                NSDictionary *dict = @{
                                       @"session": session,
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

+ (NSString*)databasePath
{
    NSString *dbPath;
#ifdef DEBUG
    dbPath = @"ringmail_dev";
#else
    dbPath = @"ringmail";
#endif
    dbPath = [dbPath stringByAppendingString:@"_v1.2.5.db"];
    return dbPath;
}

- (FMDatabaseQueue *)database
{
    if (databaseQueue == nil)
    {
        NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
        NSString *dbPath = [docsPath stringByAppendingPathComponent:[RgChatManager databasePath]];
        self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    }
    return self.databaseQueue;
}

- (void)setupDatabase
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        NSArray *setup = [NSArray arrayWithObjects:
                                //@"DROP TABLE session;",
                                @"CREATE TABLE IF NOT EXISTS session ("
                                    "id INTEGER PRIMARY KEY NOT NULL,"
                                    "contact_id bigint,"
                                    "favorite tinyint(1) NOT NULL DEFAULT '0',"
                                    "hide bigint NOT NULL DEFAULT 0,"
                                    "label varchar(255) DEFAULT NULL,"
                                    "session_md5 text NOT NULL,"
                                    "session_tag text NOT NULL,"
                                    "ts_last_event datetime NOT NULL,"
                                    "unread bigint NOT NULL DEFAULT 0"
                                ");",
                          
                                @"CREATE UNIQUE INDEX IF NOT EXISTS contact_id_1 ON session (contact_id);",
                                @"CREATE UNIQUE INDEX IF NOT EXISTS session_tag_1 ON session (session_tag);",
                                @"CREATE INDEX IF NOT EXISTS session_md5_1 ON session (session_md5);",
                                @"CREATE INDEX IF NOT EXISTS ts_last_event_1 ON session (ts_last_event);",
								
                                @"CREATE TABLE IF NOT EXISTS chat (session_id INTEGER NOT NULL, msg_body TEXT NOT NULL, msg_time TEXT NOT NULL, msg_inbound INTEGER, msg_uuid TEXT NOT NULL, msg_status TEXT NOT NULL DEFAULT '', msg_data BLOB DEFAULT NULL, msg_type TEXT DEFAULT 'text/plain', msg_url TEXT DEFAULT NULL);",
                                @"CREATE INDEX IF NOT EXISTS session_id_1 ON chat (session_id);",
                                @"CREATE INDEX IF NOT EXISTS msg_uuid_1 ON chat (msg_uuid);",
								
								@"CREATE TABLE IF NOT EXISTS calls ("
                                  "id INTEGER PRIMARY KEY NOT NULL,"
                                  "call_duration bigint DEFAULT 0,"
                                  "call_inbound tinyint(1) NOT NULL DEFAULT '0',"
                                  "call_sip text NOT NULL,"
                                  "call_state text NOT NULL,"
                                  "call_status text,"
                                  "call_time text NOT NULL,"
                                  "call_uuid text,"
                                  "session_id bigint NOT NULL DEFAULT 0"
                                ");",
                                @"CREATE INDEX IF NOT EXISTS call_sip_1 ON calls (call_sip);",
                                @"CREATE INDEX IF NOT EXISTS call_uuid_1 ON calls (call_uuid);",
                                @"CREATE INDEX IF NOT EXISTS session_id_1 ON calls (session_id);",
								
								@"CREATE TABLE IF NOT EXISTS favorites (id INTEGER PRIMARY KEY NOT NULL, contact_id bigint NOT NULL);",
								@"CREATE UNIQUE INDEX IF NOT EXISTS contact_id_1 ON favorites (contact_id);",
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
								@"DROP TABLE favorites",
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

- (NSDictionary*)dbGetSessionData:(NSNumber*)rowid
{
	FMDatabaseQueue *dbq = [self database];
    __block NSDictionary* result = nil;
    [dbq inDatabase:^(FMDatabase *db) {
        NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
		NSArray *res = [ndb get:@{
			@"table":  @"session",
			@"where": @{
				@"rowid": rowid,
			},
		}];
		result = res[0];
    }];
    [dbq close];
    return result;
}

- (NSNumber *)dbGetSessionID:(NSString *)from contact:(NSNumber*)contact
{
    //NSLog(@"RingMail: Chat - Session ID:(%@)", from);
    FMDatabaseQueue *dbq = [self database];
    __block NSNumber* result;
    [dbq inDatabase:^(FMDatabase *db) {
		BOOL contact_found = NO;
        FMResultSet *rs = [db executeQuery:@"SELECT rowid FROM session WHERE session_tag = ? COLLATE NOCASE", from];
        if ([rs next])
        {
            result = [NSNumber numberWithLong:[rs longForColumnIndex:0]];
            contact_found = YES;
        }
        else
        {
            NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
            [ndb set:@{
                       @"table": @"session",
                       @"insert": @{
                               @"session_tag": from,
                               @"contact_id": (contact != nil) ? contact : [NSNull null],
                               @"session_md5": [from md5HexDigest],
                               @"unread": @0,
                               @"ts_last_event": [[NSDate date] strftime],
                           },
                       }];
            result = [NSNumber numberWithLongLong:[db lastInsertRowId]];
        }
        [rs close];
		if ((! contact_found) && (contact != nil))
		{
    		FMResultSet *rs = [db executeQuery:@"SELECT rowid FROM session WHERE contact_id = ?", contact];
            if ([rs next])
            {
                result = [NSNumber numberWithLong:[rs longForColumnIndex:0]];
            }
			[rs close];
		}
    }];
    [dbq close];
    return result;
}

- (void)dbUpdateSessionTimestamp:(NSNumber *)session timestamp:(NSDate *)event
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT strftime('%s', ts_last_event) FROM session WHERE rowid = ? and ts_last_event != '0000-00-00 00:00:00'", session];
        NSDate *current = nil;
        if ([rs next])
        {
            current = [NSDate dateWithTimeIntervalSince1970:[rs doubleForColumnIndex:0]];
        }
        [rs close];
        //NSLog(@"Check Timestamp For: %@ From: %@ To %@", session, current, event);
        if (current == nil || [event compare:current] == NSOrderedDescending)
        {
            //NSLog(@"Update Timestamp For: %@ From: %@ To %@", session, current, event);
            NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
            [ndb set:@{
                       @"table": @"session",
                       @"update": @{
                               @"ts_last_event": [event strftime],
                           },
                       @"where": @{
                               @"rowid": session,
                           },
                       }];
        }
    }];
    [dbq close];
}

- (void)dbDeleteSessionID:(NSNumber *)session
{
    //NSLog(@"RingMail: Chat Delete - Session ID:(%@)", from);
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM chat WHERE session_id = ?;", session];
        [db executeUpdate:@"DELETE FROM calls WHERE session_id = ?;", session];
        [db executeUpdate:@"DELETE FROM session WHERE rowid = ?;", session];
    }];
    [dbq close];
}

- (void)dbInsertMessage:(NSNumber *)session type:(NSString *)type data:(NSDictionary*)params uuid:(NSString*)uuid inbound:(BOOL)inbound url:(NSString*)msgUrl
{
    __block NSString* status = (inbound) ? @"" : @"sending";
    __block NSString* body = @"";
    __block NSData* msgData = [NSData data];
    NSObject *url = msgUrl;
    if (url == nil)
    {
        url = [NSNull null];
    }
    if ([type isEqualToString:@"text/plain"])
    {
        body = [params objectForKey:@"body"];
    }
    else if ([type isEqualToString:@"image/png"])
    {
        msgData = [params objectForKey:@"image"];
    }
    else if ([type isEqualToString:@"application/json"])
    {
        msgData = [params objectForKey:@"data"];
    }
    else
    {
        NSLog(@"RingMail Error: Invalid message type: '%@'", type);
    }
	if (msgData == nil)
	{
		msgData = [NSData data];
	}
    NSDate *timestamp = [params objectForKey:@"timestamp"];
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
        [ndb set:@{
                   @"table":@"chat",
                   @"insert": @{
                           @"session_id": session,
                           @"msg_body": body,
                           @"msg_time": [timestamp strftime],
                           @"msg_inbound": [NSNumber numberWithBool:inbound],
                           @"msg_uuid": uuid,
                           @"msg_status": status,
                           @"msg_type": type,
                           @"msg_data": msgData,
                           @"msg_url": url,
                }
        }];
        if (inbound)
        {
            [db executeUpdate:@"UPDATE session SET unread = unread + 1 WHERE rowid = ?", session];
        }
    }];
    [dbq close];
    [self dbUpdateSessionTimestamp:session timestamp:timestamp];
}

- (NSNumber*)dbUpdateMessageStatus:(NSString*)status forUUID:(NSString*)uuid
{
	__block NSNumber* session = nil;
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
		NoteRow *chatRow = [ndb row:@"chat" where:@{@"msg_uuid": uuid}];
		if (chatRow != nil)
		{
			[chatRow update:@{
				@"msg_status": status,
			}];
			session = (NSNumber*)[chatRow data:@"session_id"];
		}
    }];
    [dbq close];
	if (session != nil)
	{
		[self dbUpdateSessionTimestamp:session timestamp:[NSDate date]];
	}
	return session;
}

- (NSNumber*)dbUpdateMessageData:(NSData*)data forUUID:(NSString*)uuid
{
	__block NSNumber* session = nil;
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
		NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
		NoteRow *chatRow = [ndb row:@"chat" where:@{@"msg_uuid": uuid}];
		if (chatRow != nil)
		{
			[chatRow update:@{
				@"msg_data": data,
			}];
			session = (NSNumber*)[chatRow data:@"session_id"];
		}
    }];
    [dbq close];
	if (session != nil)
	{
		[self dbUpdateSessionTimestamp:session timestamp:[NSDate date]];
	}
	return session;
}

- (NSArray *)dbGetSessions
{
    FMDatabaseQueue *dbq = [self database];
    __block NSMutableArray *result = [NSMutableArray array];
    [dbq inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT session_tag, unread, (SELECT msg_body FROM chat WHERE chat.session_id=session.rowid AND msg_type = 'text/plain' ORDER BY rowid DESC LIMIT 1) as last_message, (SELECT STRFTIME('%s', msg_time) FROM chat WHERE chat.session_id=session.rowid AND msg_type = 'text/plain' ORDER BY rowid DESC LIMIT 1) as last_time, (SELECT call_sip FROM calls WHERE calls.session_id=session.rowid ORDER BY rowid DESC LIMIT 1) as call_id, (SELECT STRFTIME('%s', call_time) FROM calls WHERE calls.session_id=session.rowid ORDER BY rowid DESC LIMIT 1) as call_time, contact_id FROM session ORDER BY rowid DESC"];
        while ([rs next])
        {
            //NSLog(@"RingMail Chat Result Set: %@", [rs resultDictionary]);
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
                               [rs objectForColumnIndex:6],
                               nil]];
        }
        [rs close];
    }];
    //NSLog(@"RingMail dbGetSession: %@", result);
    [dbq close];
    return result;
}

- (NSArray *)dbGetMainList
{
    return [self dbGetMainList:nil favorites:NO];
}

- (NSArray *)dbGetMainList:(NSNumber *)session
{
    return [self dbGetMainList:session favorites:NO];
}

- (NSArray *)dbGetMainList:(NSNumber *)session favorites:(BOOL)fav
{
    FMDatabaseQueue *dbq = [self database];
    __block NSMutableArray *result = [NSMutableArray array];
    [dbq inDatabase:^(FMDatabase *db) {
        NSString *sql = @"";
        sql = [sql stringByAppendingString:@"SELECT rowid, session_tag, unread, contact_id, STRFTIME('%s', ts_last_event) AS timestamp, "];
        sql = [sql stringByAppendingString:@"(SELECT msg_body FROM chat WHERE chat.session_id=session.rowid AND msg_type = 'text/plain' ORDER BY rowid DESC LIMIT 1) as last_message, "];
        sql = [sql stringByAppendingString:@"(SELECT STRFTIME('%s', msg_time) FROM chat WHERE chat.session_id=session.rowid AND msg_type = 'text/plain' ORDER BY rowid DESC LIMIT 1) as last_time, "];
	    sql = [sql stringByAppendingString:@"(SELECT msg_inbound FROM chat WHERE chat.session_id=session.rowid AND msg_type = 'text/plain' ORDER BY rowid DESC LIMIT 1) as msg_inbound, "];
        sql = [sql stringByAppendingString:@"(SELECT call_sip FROM calls WHERE calls.session_id=session.rowid ORDER BY rowid DESC LIMIT 1) as call_id, "];
        sql = [sql stringByAppendingString:@"(SELECT STRFTIME('%s', call_time) FROM calls WHERE calls.session_id=session.rowid ORDER BY rowid DESC LIMIT 1) as call_time, "];
        sql = [sql stringByAppendingString:@"(SELECT call_inbound FROM calls WHERE calls.session_id=session.rowid ORDER BY rowid DESC LIMIT 1) as call_inbound, "];
		sql = [sql stringByAppendingString:@"(SELECT call_duration FROM calls WHERE calls.session_id=session.rowid ORDER BY rowid DESC LIMIT 1) as call_duration, "];
		sql = [sql stringByAppendingString:@"(SELECT call_status FROM calls WHERE calls.session_id=session.rowid ORDER BY rowid DESC LIMIT 1) as call_status "];
        sql = [sql stringByAppendingString:@"FROM session "];
        if (session)
        {
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"WHERE rowid = ? "]];
        }
        else if (fav)
        {
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"WHERE favorite = 1 "]];
        }
		else
		{
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"WHERE EXISTS (SELECT msg_body FROM chat WHERE chat.session_id=session.rowid AND msg_type = 'text/plain') OR EXISTS (SELECT * FROM calls WHERE calls.session_id=session.rowid) "]];
		}
        sql = [sql stringByAppendingString:@"ORDER BY ts_last_event DESC, rowid DESC"];
        FMResultSet *rs;
        if (session)
        {
            rs = [db executeQuery:sql, session];
        }
        else
        {
            rs = [db executeQuery:sql];
        }
        while ([rs next])
        {
			NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[rs resultDictionary]];
            NSLog(@"Item: %@", item);
            NSString* last = [item objectForKey:@"last_message"];
            if (last == nil)
            {
                last = @"";
            }
			[item setObject:last forKey:@"last_message"];
            [result addObject:item];
        }
        [rs close];
    }];
    NSLog(@"dbGetMainList: %@", result);
    [dbq close];
    return result;
}

- (NSArray *)dbGetMessages:(NSNumber *)session
{
    return [self dbGetMessages:(NSNumber *)session uuid:nil];
}

- (NSArray *)dbGetMessages:(NSNumber *)session uuid:(NSString*)uuid;
{
    FMDatabaseQueue *dbq = [self database];
    __block NSMutableArray *result = [NSMutableArray array];
    __block BOOL notify = NO;
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
        FMResultSet *urs = [db executeQuery:@"SELECT unread FROM session WHERE rowid = ?", session];
        if ([urs next])
        {
             if ([urs longForColumnIndex:0] > 0)
             {
                 [db executeUpdate:@"UPDATE session SET unread = 0 WHERE rowid = ?", session];
                 notify = YES;
             }
        }
        [urs close];
    }];
    [dbq close];
    if (notify)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kRgMainRefresh object:self userInfo:nil];
    }
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

- (NSNumber *)dbGetSessionByMD5:(NSString*)lookup
{
    //NSLog(@"RingMail: Chat - Session MD5:(%@)", lookup);
    if (! [lookup isMatchedByRegex:@"^[A-Fa-f0-9]{6,32}$"])
    {
        return [NSNumber numberWithInt:0];
    }
    lookup = [lookup stringByAppendingString:@"%"];
    FMDatabaseQueue *dbq = [self database];
    __block NSNumber* result = [NSNumber numberWithInt:0];
    [dbq inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT rowid FROM session WHERE session_md5 LIKE ?", lookup];
        if ([rs next])
        {
            result = [rs objectForColumnIndex:0];
        }
        [rs close];
    }];
    [dbq close];
    return result;
}

- (void)dbInsertCall:(NSDictionary*)callData session:(NSNumber*)session
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
        [ndb set:@{
            @"table":@"calls",
            @"insert": @{
                @"session_id":session,
                @"call_sip":[callData objectForKey:@"sip"],
                @"call_state":[callData objectForKey:@"state"],
                @"call_inbound":[callData objectForKey:@"inbound"],
                @"call_time":[[NSDate date] strftime],
                @"call_status":@"created",
            }
        }];
    }];
    [dbq close];
	[self dbUpdateSessionTimestamp:session timestamp:[NSDate date]];
}

- (void)dbUpdateCall:(NSDictionary*)callData
{
	__block NSNumber* session = nil;
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
		NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
		NoteRow *callRow = [ndb row:@"calls" where:@{@"call_sip": [callData objectForKey:@"sip"]}];
		if (callRow != nil)
		{
			session = (NSNumber*)[callRow data:@"session_id"];
			NSMutableDictionary *updated = [NSMutableDictionary dictionary];
			for (NSString *k in @[@"state", @"status", @"duration"])
			{
				NSObject *val = [callData objectForKey:k];
				if (val != nil)
				{
					NSString *nk = [NSString stringWithFormat:@"call_%@", k];
					[updated setObject:val forKey:nk];
				}
			}
			[callRow update:updated];
		}
        if ([callData[@"status"] isEqualToString:@"missed"])
        {
            [db executeUpdate:@"UPDATE session SET unread = unread + 1 WHERE rowid = ?", session];
        }
    }];
    [dbq close];
	if (session != nil)
	{
		[self dbUpdateSessionTimestamp:session timestamp:[NSDate date]];
	}
}

- (void)dbAddFavorite:(NSNumber *)session
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
		[ndb set:@{
			@"table":@"session",
            @"update":@{
                @"favorite": [NSNumber numberWithBool:YES],
            },
			@"where": @{@"rowid": session},
        }];
    }];
    [dbq close];
}

- (void)dbDeleteFavorite:(NSNumber *)session
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
       		[ndb set:@{
			@"table":@"session",
            @"update":@{
                @"favorite": [NSNumber numberWithBool:NO],
            },
			@"where": @{@"rowid": session},
        }];
    }];
    [dbq close];
}

- (BOOL)dbIsFavorite:(NSNumber *)session
{
    __block BOOL res = NO;
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
		NSArray* q = [ndb get:@{
			@"table":@"session",
            @"select":@[
                @"favorite",
            ],
			@"where": @{@"rowid": session},
        }];
        if ([q count] > 0)
        {
            res = [[[q objectAtIndex:0] objectForKey:@"favorite"] boolValue];
        }
    }];
    [dbq close];
    return res;
}



@end
