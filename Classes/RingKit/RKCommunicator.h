//
//  RKCommunicator.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

extern NSString *const kRKItemActivity;
extern NSString *const kRKMessageSent;
extern NSString *const kRKMessageReceived;
extern NSString *const kRKMessageUpdated;
extern NSString *const kRKMessageRemoved;
extern NSString *const kRKCallBegin;
extern NSString *const kRKCallUpdated;
extern NSString *const kRKCallEnd;

@class RKAdapterXMPP;
@class RKAddress;
@class RKContact;
@class RKThread;
@class RKCall;
@class RKMessage;
@class RKMomentMessage;

@protocol RKCommunicatorViewDelegate <NSObject>
@optional

- (void)showMessageView:(RKThread*)thread;
//- (void)showCallView;
- (void)showHashtagView:(NSString*)hashtag;
- (void)showContactView:(NSNumber*)contactId;
- (void)showImageView:(UIImage*)image parameters:(NSDictionary*)params;
- (void)showMomentView:(UIImage*)image parameters:(NSDictionary*)params complete:(void(^)(void))complete;
- (void)startCall:(RKAddress*)dest video:(BOOL)video;
- (void)showNewMessage:(RKMessage*)msg;
- (void)enableMessageNotifications:(BOOL)show;

@end

// ---------------------------------------------

@interface RKCommunicator : NSObject

@property (nonatomic, strong) RKAdapterXMPP* adapterXMPP;
@property (nonatomic, weak) id<RKCommunicatorViewDelegate>viewDelegate;

+ (instancetype)sharedInstance;

- (void)sendMessage:(RKMessage*)message;
- (void)didReceiveMessage:(RKMessage*)message;
- (void)didUpdateMessage:(RKMessage*)message;

- (void)startCall:(RKAddress*)dest video:(BOOL)video;
- (void)didBeginCall:(RKCall*)call;
- (void)didUpdateCall:(RKCall*)call;
- (void)didEndCall:(RKCall*)call;

- (NSArray*)listThreads;
- (NSArray*)listThreadItems:(RKThread*)thread;
- (NSArray*)listThreadItems:(RKThread*)thread lastItemId:(NSNumber*)lastItemId;
- (RKThread*)getThreadById:(NSNumber*)lookupId;
- (RKThread*)getThreadByMD5:(NSString*)lookupHash;
- (RKThread*)getThreadByAddress:(RKAddress*)remoteAddress;
- (RKThread*)getThreadByAddress:(RKAddress*)remoteAddress orignalTo:(RKAddress*)origTo contactId:(NSNumber*)ctid uuid:(NSString*)uuid;
- (RKCall*)getCallBySipId:(NSString*)sip;
- (RKMessage*)getMessageByUUID:(NSString*)inputUUID;

- (void)startMessageView:(RKThread*)thread;
- (void)startMomentView:(RKMomentMessage*)msg;
//- (void)startCallView:(RKAddress*)address;
- (void)startContactView:(RKContact*)contact;
- (void)startHashtagView:(NSString*)hashtag;
- (void)startImageView:(UIImage*)image parameters:(NSDictionary*)params;
- (void)enableMessageNotifications:(BOOL)show;

@end

