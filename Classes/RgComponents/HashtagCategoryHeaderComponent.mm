#import "HashtagCategoryHeaderComponent.h"
#import "HashtagModelController.h"
#import "Card.h"

#import "CardContext.h"

#import "UIColor+Name.h"
#import "UIColor+Hex.h"

@implementation HashtagCategoryHeaderComponent

@synthesize cardData;

CKInsetComponent* hashtagCatDirHeaderLabelComponent(float*, NSDictionary*);


+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    NSString* hdht = data[@"header_img_ht"];
    
    HashtagCategoryHeaderComponent *c = [super newWithComponent:
        [CKInsetComponent
        newWithInsets:{.top = 0, .left = 0, .bottom = 0, .right = 0}
        component:
        [CKStackLayoutComponent newWithView:{
            [UIView class],{
                {@selector(setBackgroundColor:), [UIColor whiteColor]},
            }}
            size:{.width = screenWidth}
            style:{}
            children:{
                {[CKNetworkImageComponent newWithURL:data[@"header_img_url"]
                                     imageDownloader:context.imageDownloader
                                           scenePath:nil size:{ screenWidth, [hdht floatValue] } options:{} attributes:{}]},
                {hashtagCatDirHeaderLabelComponent(&screenWidth,data)},
            }
        ]]];
    
    [c setCardData:data];
    
    return c;
}


CKInsetComponent* hashtagCatDirHeaderLabelComponent(float* wIn, NSDictionary * data)
{
    return
    [
        CKInsetComponent
        newWithInsets:{.left = 20, .right = 0, .top = 18, .bottom = 20}
        component:
            [CKStackLayoutComponent
            newWithView:{}
            size:{}
            style:{.spacing = 6}
            children:{
                {[CKLabelComponent newWithLabelAttributes:{
                    .string = [data objectForKey:@"category_name"],
                    .color = [UIColor colorWithHex:@"#213E87"],
                    .font = [UIFont fontWithName:@"SFUIText-SemiBold" size:24],
                    .alignment = NSTextAlignmentLeft,
                }
                    viewAttributes:{
                        {@selector(setBackgroundColor:), [UIColor clearColor]},
                        {@selector(setUserInteractionEnabled:), @NO},
                    }
                    size:{.width = *wIn}]},
                {[CKLabelComponent newWithLabelAttributes:{
                    .string = [data objectForKey:@"parent_name"],
                    .color = [UIColor colorWithHex:@"#222222"],
                    .font = [UIFont fontWithName:@"SFUIText-Light" size:19],
                    .alignment = NSTextAlignmentLeft,
                }
                    viewAttributes:{
                        {@selector(setBackgroundColor:), [UIColor clearColor]},
                        {@selector(setUserInteractionEnabled:), @NO},
                    }
                    size:{.width = *wIn}]},
            }]
    ];
}

@end
