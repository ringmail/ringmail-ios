//
//  RKMessage.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKMediaMessage.h"
#import "RKAddress.h"
#import "RKThread.h"
#import "RKThreadStore.h"

#import "RgManager.h"
#import "RgNetwork.h"
#import "Utils.h"
#import "NSXMLElement+XMPP.h"

@implementation RKMediaMessage

@synthesize remoteURL;
@synthesize mediaData;
@synthesize mediaType;
@synthesize localPath;

+ (instancetype)newWithData:(NSDictionary*)param
{
	return [[RKMediaMessage alloc] initWithData:param];
}

- (instancetype)initWithData:(NSDictionary*)param
{
	self = [super initWithData:param];
	if (self)
	{
		if (param[@"remoteURL"])
        {
            NSAssert([param[@"remoteURL"] isKindOfClass:[NSURL class]], @"remoteURL is not NSURL object");
            [self setRemoteURL:param[@"remoteURL"]];
        }
		else
		{
			self->remoteURL = nil;
		}
		if (param[@"mediaData"])
        {
            NSAssert([param[@"mediaData"] isKindOfClass:[NSData class]], @"mediaData is not NSData object");
            [self setMediaData:param[@"mediaData"]];
        }
		else
		{
			self->mediaData = nil;
		}
		if (param[@"mediaType"])
        {
            NSAssert([param[@"mediaType"] isKindOfClass:[NSString class]], @"mediaType is not NSString object");
            [self setMediaType:param[@"mediaType"]];
        }
		else
		{
			self->mediaType = nil;
		}
		if (param[@"localPath"])
        {
            NSAssert([param[@"localPath"] isKindOfClass:[NSString class]], @"localPath is not NSString object");
            [self setLocalPath:param[@"localPath"]];
        }
		else
		{
			self->localPath = nil;
		}
	}
	return self;
}

- (NSString*)description
{
	NSDictionary* input = @{
		@"itemId": NULLIFNIL(self.itemId),
		@"messageId": NULLIFNIL(self.messageId),
		@"version": self.version,
		@"thread": [NSString stringWithFormat:@"<RKThread: %p>", self.thread],
		@"uuid": self.uuid,
		@"inbound": [NSNumber numberWithInteger:self.direction],
		@"timestamp": self.timestamp,
		@"body": self.body,
		@"deliveryStatus": _RKMessageStatus(self.deliveryStatus),
		@"remoteURL": NULLIFNIL(self.remoteURL),
		@"mediaType": NULLIFNIL(self.mediaType),
	};
    NSMutableString *data = [[NSMutableString alloc] init];
    for (NSString *k in input.allKeys)
	{
        [data appendFormat:@" %@:%@", k, input[k]];
	}
	return [NSString stringWithFormat:@"<%s: %p {%@ }>", object_getClassName(self), self, data];
}

- (void)insertItem:(NoteDatabase*)ndb
{
	NSAssert(self.thread.threadId, @"thread id required");
	[ndb set:@{
		@"table": @"rk_message",
		@"insert": @{
			@"thread_id": self.thread.threadId,
			@"msg_type": [self mediaType],
			@"msg_class": [NSString stringWithCString:object_getClassName(self) encoding:NSASCIIStringEncoding],
			@"msg_time": [[self timestamp] strftime],
			@"msg_status": [NSNumber numberWithInteger:[self deliveryStatus]],
			@"msg_uuid": [self uuid],
			@"msg_inbound": [NSNumber numberWithInteger:[self direction]],
			@"msg_body": [self body],
			@"msg_remote_url": NULLIFNIL([self remoteURL]),
		},
	}];
	NSNumber* detailId = [ndb lastInsertId];
	self.messageId = detailId;
	[ndb set:@{
		@"table": @"rk_thread_item",
		@"insert": @{
			@"thread_id": self.thread.threadId,
			@"message_id": detailId,
			@"ts_created": [[self timestamp] strftime],
		},
	}];
	self.itemId = [ndb lastInsertId];
}

- (void)updateItem:(NoteDatabase*)ndb
{
	NSAssert(self.messageId, @"message id required");
	[ndb set:@{
		@"table": @"rk_message",
		@"update": @{
			@"msg_status": [NSNumber numberWithInteger:[self deliveryStatus]],
			@"msg_remote_url": NULLIFNIL([self remoteURL]),
		},
		@"where": @{
			@"id": [self messageId],
		},
	}];
}

// TODO: add error handlers
- (void)uploadMedia:(void (^)(BOOL success))complete
{
	NSString *ct = [self mediaType];
	NSString *ext = nil;
	if ([ct isEqualToString:@"image/png"])
	{
		ext = @"png";
	}
	else if ([ct isEqualToString:@"image/jpeg"])
	{
		ext = @"jpg";
	}
	else if ([ct isEqualToString:@"video/mp4"])
	{
		ext = @"mov";
	}
	NSAssert(ext, @"Invalid mime type for upload");
	RgNetworkCallback cb = ^(NSURLSessionTask *operation, id responseObject) {
        NSDictionary* res = responseObject;
		NSLog(@"Upload Result: %@", res);
        NSString *ok = res[@"result"];
        if ([ok isEqualToString:@"ok"])
        {
			self.remoteURL = [NSURL URLWithString:res[@"url"]];
			[[RKThreadStore sharedInstance] updateItem:self];
			complete(TRUE);
		}
		else
		{
			complete(FALSE);
		}
	};
	if (self.localPath != nil)
	{
		[[RgNetwork instance] uploadURL:[self documentURL] mimeType:ct extension:ext uuid:self.uuid callback:cb];
	}
	else
	{
		[[RgNetwork instance] uploadData:self.mediaData mimeType:ct extension:ext uuid:self.uuid callback:cb];
	}
}

// TODO: add error handlers
- (void)downloadMedia:(void (^)(BOOL success))complete
{
	NSAssert(self.remoteURL, @"Remote URL required");
	NSString* url = [self.remoteURL absoluteString];
    [[RgNetwork instance] downloadData:url callback:^(NSURLSessionTask *operation, id responseObject) {
        NSLog(@"%s: Download Complete", __PRETTY_FUNCTION__);
        NSData* imageData = responseObject;
		self.mediaType = @"image/png"; // TODO: customize
		[imageData writeToURL:[self documentURL] atomically:YES];
		complete(TRUE);
    }];
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL*)documentURL
{
	NSString* mainUuid = [self uuid];
	NSString* otherPath = [self localPath];
	NSURL* url = [self applicationDocumentsDirectory];
	NSString* urlStr = [url absoluteString];
	if (otherPath != nil)
	{
		urlStr = [urlStr stringByAppendingPathComponent:otherPath];
	}
	else
	{
		urlStr = [urlStr stringByAppendingPathComponent:mainUuid];
	}
	url = [NSURL URLWithString:urlStr];
	return url;
}

@end
