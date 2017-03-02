/* This file provided by Facebook is for non-commercial testing and evaluation
 * purposes only.  Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "HashtagCategoryCardComponent.h"
#import "Card.h"

#import "CardContext.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"
#import "UIColor+Name.h"
#import "UIColor+Hex.h"

#import "RgCustomView.h"

@implementation HashtagCategoryCardComponent

@synthesize cardData;

CKComponent* hashtagCatImgComponent(UIImage*, CGFloat*);
CKInsetComponent* hashtagCatInsetLabelComponent(NSDictionary*);


+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	CGFloat screenWidth = screenRect.size.width;
	CGFloat itemWidth = screenWidth / 2;
	CGFloat rectWidth = itemWidth - 20;

//    UIImage* test = [UIImage imageNamed:@"explore_hashtagdir_full1@iph6-7p@3x.jpg"];
    
    HashtagCategoryCardComponent *c = [super newWithComponent:
        [CKInsetComponent
        newWithInsets:{.top = 0, .left = 6, .bottom = 12, .right = 6}
        component:
            [CKStackLayoutComponent newWithView:{
                [UIView class],{
                    {CKComponentTapGestureAttribute(@selector(actionSelect:))},
                    {CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), @20.0},
                    {@selector(setClipsToBounds:), @YES},
                    {@selector(setBackgroundColor:), [UIColor whiteColor]},
                    {CKComponentViewAttribute::LayerAttribute(@selector(setBorderColor:)), (id)[[UIColor colorWithHex:@"#C0C1C2"] CGColor]},
                    {CKComponentViewAttribute::LayerAttribute(@selector(setBorderWidth:)), 1 / [UIScreen mainScreen].scale},
                }}
            size:{.width = rectWidth}
            style:{}
            children:{
                {[CKNetworkImageComponent newWithURL:data[@"image_url"]
                                     imageDownloader:context.imageDownloader
                                           scenePath:nil size:{ rectWidth, rectWidth * 0.73 } options:{} attributes:{}]},
//                {hashtagCatImgComponent(data[@"image_url"],&rectWidth)},
                {hashtagCatInsetLabelComponent(data)},
            }
        ]]];
    
    [c setCardData:data];

    return c;
}


CKComponent* hashtagCatImgComponent(UIImage* imgIn, CGFloat* wIn)
{
    return
    [
        CKComponent newWithView:{
            [UIImageView class],
            {
              {@selector(setImage:), imgIn},
              {@selector(setContentMode:), @(UIViewContentModeScaleAspectFill)},
            }
        }
        size:{*wIn, *wIn / (imgIn.size.width/imgIn.size.height)}
    ];
}


CKInsetComponent* hashtagCatInsetLabelComponent(NSDictionary* data)
{
    return
    [
         CKInsetComponent newWithInsets:
            {.left = 10, .right = 10, .top = 4, .bottom = INFINITY}
            component: [
                CKLabelComponent newWithLabelAttributes:{
                    .string = [data objectForKey:@"name"],
                    .font = [UIFont fontWithName:@"SFUIText-Regular" size:13],
                    .color = [UIColor colorWithHex:@"#222222"],
                    .alignment = NSTextAlignmentLeft,
                }
                viewAttributes:{
                   {@selector(setBackgroundColor:), [UIColor clearColor]},
                   {@selector(setUserInteractionEnabled:), @NO},
                }
                size:{}
            ]
    ];
}


- (void)actionSelect:(CKButtonComponent *)sender
{
    //Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    //[card showMessages];
//    NSLog(@"Selected: %@", [[self cardData] objectForKey:@"name"]);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RgHashtagDirectoryUpdatePath" object:self userInfo:@{
        @"category_id":[[self cardData] objectForKey:@"id"]
    }];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"header"] = @"Hashtag Card";
    dict[@"lSeg"] = @"";
    dict[@"rSeg"] = @"";
    [[NSNotificationCenter defaultCenter] postNotificationName:@"navBarViewChange" object:nil userInfo:dict];
}


@end
