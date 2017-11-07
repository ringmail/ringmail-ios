#import <ComponentKit/ComponentKit.h>

@class CardContext;

@interface DynamicComponent : CKCompositeComponent

@property (nonatomic, retain) NSDictionary *data;

+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context;

@end
