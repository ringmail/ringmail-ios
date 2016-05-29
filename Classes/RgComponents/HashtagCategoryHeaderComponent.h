#import <ComponentKit/ComponentKit.h>

@class CardContext;

@interface HashtagCategoryHeaderComponent : CKCompositeComponent

@property (nonatomic, retain) NSDictionary *cardData;

+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context;

@end
