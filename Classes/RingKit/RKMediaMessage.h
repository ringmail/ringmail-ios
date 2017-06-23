//
//  RKMessage.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

#import "RKMessage.h"

@interface RKMediaMessage : RKMessage

@property (nonatomic, strong) NSURL* remoteURL;
@property (nonatomic, strong) NSData* mediaData;
@property (nonatomic, strong) NSString* mediaType;
@property (nonatomic, strong) NSString* localPath;

+ (instancetype)newWithData:(NSDictionary*)param;

- (instancetype)initWithData:(NSDictionary*)param;
- (void)uploadMedia:(void (^)(BOOL success))complete;
- (void)downloadMedia:(void (^)(BOOL success))complete;
- (NSURL*)documentURL;
- (NSURL*)applicationDocumentsDirectory;

@end
