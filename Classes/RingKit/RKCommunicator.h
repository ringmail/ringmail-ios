//
//  RKCommunicator.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

extern NSString *const kRKMessageSent;
extern NSString *const kRKMessageReceived;
extern NSString *const kRKMessageUpdated;

@protocol RKCommunicatorViewDelegate <NSObject>
@optional

- (void)showMessageView;
//- (void)showCallView;
- (void)showHashtagView:(NSString*)hashtag;
- (void)showContactView:(NSNumber*)contactId;

@end

@class RKAdapterXMPP;
@class RKAddress;
@class RKContact;
@class RKThread;
@class RKMessage;

@interface RKCommunicator : NSObject

@property (nonatomic, strong) RKAdapterXMPP* adapterXMPP;
@property (nonatomic, strong) RKThread* currentThread;
@property (nonatomic, weak) id<RKCommunicatorViewDelegate>viewDelegate;

+ (instancetype)sharedInstance;

- (void)sendMessage:(RKMessage*)message;
- (void)didReceiveMessage:(RKMessage*)message;

- (NSArray*)listThreads;
- (NSArray*)listThreadItems:(RKThread*)thread;
- (NSArray*)listThreadItems:(RKThread*)thread lastItemId:(NSNumber*)lastItemId;
- (RKThread*)getThreadByAddress:(RKAddress*)remoteAddress orignalTo:(RKAddress*)origTo contactId:(NSNumber*)ctid uuid:(NSString*)uuid;

- (void)startMessageView:(RKThread*)thread;
//- (void)startCallView:(RKAddress*)address;
- (void)startContactView:(RKContact*)contact;
- (void)startHashtagView:(NSString*)hashtag;

@end

