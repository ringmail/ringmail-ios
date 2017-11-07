#import "DynamicComponent.h"
#import "Card.h"

#import "CardContext.h"

#import "UIColor+Name.h"
#import "UIColor+Hex.h"

#import "RgManager.h"

@implementation DynamicComponent

@synthesize data;

+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	CGFloat screenWidth = screenRect.size.width;
	NSDictionary *place = data[@"component"];
    
    DynamicComponent *c = [super newWithComponent:
        [CKStackLayoutComponent newWithView:{
            [UIView class], {}
        } size:{.width = screenWidth}
        style:{
            .direction = CKStackLayoutDirectionVertical
        }
        children:{
            {[CKInsetComponent newWithInsets:{.left = 10, .right = 10, .top = 5, .bottom = 5} component:
                [CKLabelComponent newWithLabelAttributes:{
                    .string = place[@"name"],
                    .font = [UIFont fontWithName:@"SFUIText-Regular" size:24],
                    .color = [UIColor blackColor],
                    .alignment = NSTextAlignmentLeft,
                }
                viewAttributes:{
                    {@selector(setBackgroundColor:), [UIColor clearColor]},
                    {@selector(setUserInteractionEnabled:), @NO},
                } size:{}]
             ]},
             {[CKInsetComponent newWithInsets:{.left = 10, .right = 10, .top = 5, .bottom = 5} component:
                [CKLabelComponent newWithLabelAttributes:{
                    .string = place[@"address"],
                    .font = [UIFont fontWithName:@"SFUIText-Regular" size:24],
                    .color = [UIColor blackColor],
                    .alignment = NSTextAlignmentLeft,
                }
                viewAttributes:{
                    {@selector(setBackgroundColor:), [UIColor clearColor]},
                    {@selector(setUserInteractionEnabled:), @NO},
                } size:{}]
             ]},
             {[CKInsetComponent newWithInsets:{.left = 10, .right = 10, .top = 5, .bottom = 5} component:
                [CKLabelComponent newWithLabelAttributes:{
                    .string = place[@"locality"],
                    .font = [UIFont fontWithName:@"SFUIText-Regular" size:24],
                    .color = [UIColor blackColor],
                    .alignment = NSTextAlignmentLeft,
                }
                viewAttributes:{
                    {@selector(setBackgroundColor:), [UIColor clearColor]},
                    {@selector(setUserInteractionEnabled:), @NO},
                } size:{}]
             ]},
        }]
    ];
    [c setData:data];
    return c;
}

- (CKComponent*)buildComponent:(NSDictionary*)data
{
    NSString* type = data[@"type"];
    if ([type isEqualToString:@""])
    {
    }
}

@end
