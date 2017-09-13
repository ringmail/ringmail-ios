#import <objc/runtime.h>
#import <ComponentKit/ComponentKit.h>

#import "Send.h"
#import "SendContext.h"
#import "SendComponent.h"
#import "SendComponentController.h"
#import "SendCardComponent.h"
#import "SendViewController.h"
#import "TextInputComponent.h"
#import "SendToInputComponent.h"
#import "FavoritesBarComponent.h"
#import "MediaBarComponent.h"

#import "UIColor+Hex.h"

@implementation SendComponent

/*+ (id)initialState
{
	return [NSMutableDictionary dictionaryWithDictionary:@{}];
}*/


CKInsetComponent* actionBarComponent(float* wIn, float* lIn , float* rIn);


+ (instancetype)newWithSend:(Send *)send context:(SendContext *)context
{
	CKComponentScope scope(self);
	
	float width = [[UIScreen mainScreen] bounds].size.width;
    float leftMargin = 20;
    float rightMargin = 20;
    
    if ((width == 320) && ([[UIScreen mainScreen] bounds].size.height == 480))
    {
        leftMargin = 4;
        rightMargin = 4;
    }
    
    SendComponent *c = [super newWithView:{} component:
        [CKInsetComponent newWithInsets:{.top = 12, .bottom = 0, .left = 0, .right = 0} component:
            [CKStackLayoutComponent newWithView:{} size:{} style:{
                .direction = CKStackLayoutDirectionVertical,
                .alignItems = CKStackLayoutAlignItemsStart,
            }
            children:{
                // Message composer
                {[SendCardComponent newWithSend:send context:context]},
                // Action bar
                {actionBarComponent(&width, &leftMargin, &rightMargin)},
                // Favorites
                {[CKStackLayoutComponent newWithView:{} size:{.width = width} style:{
                    .direction = CKStackLayoutDirectionVertical,
                    .alignItems = CKStackLayoutAlignItemsStart,
                }
                children:{
                    {[CKComponent newWithView:{
                        [UIView class],
                        {
                            {@selector(setBackgroundColor:), [UIColor colorWithHex:@"#D1D1D1"]},
                        }
                    } size:{.height = 1 / [UIScreen mainScreen].scale, .width = width}]},
                    {[CKBackgroundLayoutComponent newWithComponent:
                        [CKInsetComponent newWithInsets:{.top = 0, .bottom = 0, .left = 20, .right = 0} component:
                            [CKCenterLayoutComponent newWithCenteringOptions:CKCenterLayoutComponentCenteringY sizingOptions:CKCenterLayoutComponentSizingOptionDefault child:
                                [CKLabelComponent newWithLabelAttributes:{
                                    .string = @"Favorites",
                                    .font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold],
                                    .alignment = NSTextAlignmentLeft,
                                }
                                viewAttributes:{
                                    {@selector(setBackgroundColor:), [UIColor clearColor]},
                                    {@selector(setUserInteractionEnabled:), @NO},
                                }
                                size:{.width = width - 20}]
                            size:{.width = width - 20, .height = 27}]
                        ]
                    background:
                        [CKImageComponent newWithImage:[UIImage imageNamed:@"background_favorites.png"]]
                    ]},
                    {[CKComponent newWithView:{
                        [UIView class],
                        {
                            {@selector(setBackgroundColor:), [UIColor colorWithHex:@"#D1D1D1"]},
                        }
                    } size:{.height = 1 / [UIScreen mainScreen].scale, .width = width}]},
                    {[FavoritesBarComponent newWithSize:{.height = 76, .width = width}]},
                }]},
                // Media library
                {
                    .flexGrow = YES,
                    .component = [CKStackLayoutComponent newWithView:{} size:{.width = width} style:{
                        .direction = CKStackLayoutDirectionVertical,
                        .alignItems = CKStackLayoutAlignItemsStart,
                    }
                    children:{
                        {[CKInsetComponent newWithInsets:{.top = 12, .bottom = 10, .left = 0, .right = 0} component:
                            [CKLabelComponent newWithLabelAttributes:{
                                .string = @"LIBRARY",
                                .font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold],
                                .alignment = NSTextAlignmentCenter,
                            }
                            viewAttributes:{
                                {@selector(setBackgroundColor:), [UIColor clearColor]},
                                {@selector(setUserInteractionEnabled:), @NO},
                            }
                            size:{.height = 15, .width = width}]
                        ]},
                        {[MediaBarComponent newWithMedia:[send data][@"media"] size:{.height = 71, .width = width}]},
                    }]
                },
            }]
        ]
    ];
    
    return c;
}


CKInsetComponent* actionBarComponent(float* wIn, float* lIn , float* rIn)
{
    return
    [
     CKInsetComponent newWithInsets:{.top = 17, .bottom = 22, .left = *lIn, .right = *rIn} component:
       [CKStackLayoutComponent newWithView:{
        [UIView class],
        {
            {@selector(setBackgroundColor:), [UIColor clearColor]},
        }
        } size:{.height = 47, .width = *wIn - 40} style:{
            .direction = CKStackLayoutDirectionHorizontal,
            .alignItems = CKStackLayoutAlignItemsStretch
        }
          children:{
              {[CKButtonComponent newWithTitles:{} titleColors:{} images:{
                  {UIControlStateNormal,[UIImage imageNamed:@"ringpanel_button1_camera.png"]},
              } backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(showPhotoCamera:) size:{} attributes:{} accessibilityConfiguration:{}]},
              {.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
              {[CKButtonComponent newWithTitles:{} titleColors:{} images:{
                  {UIControlStateNormal,[UIImage imageNamed:@"ringpanel_button2_video.png"]},
              } backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(showVideoCamera:) size:{} attributes:{} accessibilityConfiguration:{}]},
              {.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
              {[CKButtonComponent newWithTitles:{} titleColors:{} images:{
                  {UIControlStateNormal,[UIImage imageNamed:@"ringpanel_button3_moments.png"]},
              } backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(showMomentCamera:) size:{} attributes:{} accessibilityConfiguration:{}]},
      }]
    ];
}

@end
