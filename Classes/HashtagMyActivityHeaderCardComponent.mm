//
//  HashtagMyActivityHeaderCardComponent.c
//  ringmail
//
//  Created by Mark Baxter on 7/6/17.
//
//

#include "HashtagMyActivityHeaderCardComponent.h"
#import "HashtagModelController.h"
#import "Card.h"

#import "CardContext.h"

#import "UIColor+Name.h"
#import "UIColor+Hex.h"

@implementation HashtagMyActivityHeaderCardComponent


+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    HashtagMyActivityHeaderCardComponent *c = [super newWithComponent:
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
                {[CKInsetComponent
                  newWithInsets:{.left = 20, .right = 0, .top = 18, .bottom = 20}
                  component:
                    [CKStackLayoutComponent
                     newWithView:{}
                     size:{}
                     style:{.spacing = 6}
                     children:{
                         {[CKLabelComponent newWithLabelAttributes:{
                             .string = @"My Activity",
                             .color = [UIColor colorWithHex:@"#213E87"],
                             .font = [UIFont fontWithName:@"SFUIText-SemiBold" size:24],
                             .alignment = NSTextAlignmentLeft,
                         }
                            viewAttributes:{
                                {@selector(setBackgroundColor:), [UIColor clearColor]},
                                {@selector(setUserInteractionEnabled:), @NO},
                            }
                            size:{.width = screenWidth}]},
                         {[CKLabelComponent newWithLabelAttributes:{
                             .string = @"Hashtags",
                             .color = [UIColor colorWithHex:@"#222222"],
                             .font = [UIFont fontWithName:@"SFUIText-Light" size:19],
                             .alignment = NSTextAlignmentLeft,
                         }
                            viewAttributes:{
                                {@selector(setBackgroundColor:), [UIColor clearColor]},
                                {@selector(setUserInteractionEnabled:), @NO},
                            }
                            size:{.width = screenWidth}]},
                }]]}
            }
           ]]];
    
    return c;
}

@end
