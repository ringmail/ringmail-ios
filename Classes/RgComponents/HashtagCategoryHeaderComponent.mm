#import "HashtagCategoryHeaderComponent.h"
#import "HashtagModelController.h"
#import "Card.h"

#import "CardContext.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"
#import "UIColor+Name.h"
#import "UIColor+Hex.h"

#import "RgCustomView.h"

@implementation HashtagCategoryHeaderComponent

@synthesize cardData;

CKComponent* hashtagCatDirHeaderImgComponent(float*, UIImage*);
CKInsetComponent* hashtagCatDirHeaderLabelComponent(float*, NSDictionary*);


+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
    UIImage* headerImg = getImage(&screenWidth);
    
    HashtagCategoryHeaderComponent *c = [super newWithComponent:
        [CKInsetComponent
        newWithInsets:{.top = 0, .left = 0, .bottom = 0, .right = 0}
        component:
        [CKStackLayoutComponent newWithView:{
            [UIView class],{
                {@selector(setBackgroundColor:), [UIColor whiteColor]},
            }}
            size:{.width = screenWidth, .height=(headerImg.size.height + 106)}
            style:{}
            children:{
                {hashtagCatDirHeaderImgComponent(&screenWidth,headerImg)},
                {hashtagCatDirHeaderLabelComponent(&screenWidth,data)},
            }
        ]]];
    
    [c setCardData:data];
    
    return c;
}


UIImage* getImage(float* wIn)
{
    UIImage* tmpImg;
    
    if (*wIn == 320)
        tmpImg = [UIImage imageNamed:@"explore_hashtag_category_sample_banner1_ip5@2x.jpg"];
    else if (*wIn == 375)
        tmpImg = [UIImage imageNamed:@"explore_hashtag_category_sample_banner1_ip6-7s@2x.jpg"];
    else if (*wIn == 414)
        tmpImg = [UIImage imageNamed:@"explore_hashtag_directory_sample_banner1_ip6-7p@3x.jpg"];
    
    return tmpImg;
}


CKComponent* hashtagCatDirHeaderImgComponent(float* wIn, UIImage* iIn)
{
    return
    [
        CKComponent newWithView:{
            [UIImageView class],
            {
                {@selector(setImage:), iIn},
                {@selector(setContentMode:), @(UIViewContentModeScaleAspectFill)},
            }
        }
        size:{*wIn, *wIn / (iIn.size.width/iIn.size.height)}
    ];
}


CKInsetComponent* hashtagCatDirHeaderLabelComponent(float* wIn, NSDictionary * data)
{
    return
    [
        CKInsetComponent
        newWithInsets:{.left = 20, .right = 0, .top = 23, .bottom = 0}
        component:
            [CKStackLayoutComponent
            newWithView:{}
            size:{}
            style:{.spacing = 8}
            children:{
                {[CKLabelComponent newWithLabelAttributes:{
                    .string = [data objectForKey:@"name"],
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
                    .string = [data objectForKey:@"name"],
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


static CKComponent *lineComponent()
{
    return [CKComponent
            newWithView:{
                [UIView class],
                {
                    {@selector(setBackgroundColor:), [UIColor colorWithHex:@"#d4d5d7"]},
                }
            }
            size:{.height = 1 / [UIScreen mainScreen].scale}];
}

// mrkbxt
//- (void)actionBack:(CKButtonComponent *)sender
//{
//    //Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
//    //[card showMessages];
//    NSLog(@"Selected: %@", [[self cardData] objectForKey:@"id"]);
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"RgHashtagDirectoryUpdatePath" object:self userInfo:@{
//        @"category_id": @"0",
//    }];
//}

@end
