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

#import "MainCardComponent.h"

#import "CardContext.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"
#import "UIColor+Hex.h"

@implementation MainCardComponent

+ (instancetype)newWithText:(NSString *)text context:(CardContext *)context
{
    UIImage *cardImage = [context imageNamed:@"Card1"];
    cardImage = [cardImage thumbnailImage:40 transparentBorder:0 cornerRadius:20 interpolationQuality:kCGInterpolationHigh];
    return [super newWithComponent:
        [CKInsetComponent
        // Left and right inset of 30pts; centered vertically:
        newWithInsets:{.left = 10, .right = 10, .top = 0, .bottom = 10}
        component:
            [CKBackgroundLayoutComponent
            newWithComponent:
                [CKStackLayoutComponent newWithView:{} size:{} style:{
                    .direction = CKStackLayoutDirectionVertical,
                    .alignItems = CKStackLayoutAlignItemsStretch
                }
                children:{
                    {[CKInsetComponent
                      newWithInsets:{.left = 5, .right = 5, .top = 5, .bottom = 5}
                      component:
                          [CKStackLayoutComponent newWithView:{} size:{.height = 40} style:{
                            .direction = CKStackLayoutDirectionHorizontal,
                            .alignItems = CKStackLayoutAlignItemsStretch
                          }
                          children:{
                              {
                                  [CKImageComponent newWithImage:cardImage size:{
                                      .height = 40,
                                      .width = 40,
                                  }],
                              }, {
                                  .flexGrow = YES,
                                  .component = [CKInsetComponent
                                   newWithInsets:{.left = 7, .right = 5, .top = INFINITY, .bottom = INFINITY}
                                   component:
                                      [CKLabelComponent
                                      newWithLabelAttributes:{
                                          .string = text,
                                          .font = [UIFont fontWithName:@"SinhalaSangamMN" size:16],
                                      }
                                      viewAttributes:{
                                          {@selector(setBackgroundColor:), [UIColor clearColor]},
                                          {@selector(setUserInteractionEnabled:), @NO},
                                      }
                                      size:{}]
                                   ]
                              }, {
                                  .alignSelf = CKStackLayoutAlignSelfEnd,
                                  .component = [CKStackLayoutComponent newWithView:{} size:{.height = 40} style:{
                                      .direction = CKStackLayoutDirectionHorizontal,
                                      .alignItems = CKStackLayoutAlignItemsStretch
                                  }
                                  children:{
                                      {
                                          [CKInsetComponent
                                           newWithInsets:{.left = 0, .right = 0, .top = INFINITY, .bottom = INFINITY}
                                           component:
                                              [CKImageComponent newWithImage:[context imageNamed:@"button_video"] size:{
                                                  .height = 27,
                                                  .width = 27,
                                              }]
                                           ]
                                      }, {
                                          [CKInsetComponent
                                           newWithInsets:{.left = 10, .right = 0, .top = INFINITY, .bottom = INFINITY}
                                           component:
                                              [CKImageComponent newWithImage:[context imageNamed:@"button_call"] size:{
                                                  .height = 27,
                                                  .width = 27,
                                              }]
                                           ]
                                      }, {
                                          [CKInsetComponent
                                           newWithInsets:{.left = 10, .right = 5, .top = INFINITY, .bottom = INFINITY}
                                           component:
                                              [CKImageComponent newWithImage:[context imageNamed:@"button_chat"] size:{
                                                  .height = 27,
                                                  .width = 27,
                                              }]
                                           ]
                                      },
                                  }]
                              }
                          }]
                      ]},
                    {lineComponent()},
                    {
                        [CKStackLayoutComponent newWithView:{} size:{} style:{
                            .direction = CKStackLayoutDirectionHorizontal,
                            .alignItems = CKStackLayoutAlignItemsStretch
                        }
                       children:{
                           {
                               .flexGrow = YES,
                               .component = [CKStackLayoutComponent newWithView:{} size:{} style:{
                                   .direction = CKStackLayoutDirectionVertical,
                                   .alignItems = CKStackLayoutAlignItemsStretch
                               }
                               children:{
                                   {[CKInsetComponent
                                     newWithInsets:{.left = 20, .right = 0, .top = 15, .bottom = 0}
                                     component:
                                     [CKLabelComponent
                                      newWithLabelAttributes:{
                                          .string = @"Monday, February 1: 1:20 PM",
                                          .font = [UIFont fontWithName:@"SinhalaSangamMN" size:12],
                                          .color = [UIColor colorWithHex:@"#70726d"],
                                      }
                                      viewAttributes:{
                                          {@selector(setBackgroundColor:), [UIColor clearColor]},
                                          {@selector(setUserInteractionEnabled:), @NO},
                                      }
                                      size:{}]
                                     ]},
                                   {[CKInsetComponent
                                     newWithInsets:{.left = 20, .right = 0, .top = 12, .bottom = 15}
                                     component:
                                     [CKLabelComponent
                                      newWithLabelAttributes:{
                                          .string = text,
                                          .font = [UIFont fontWithName:@"SinhalaSangamMN" size:14],
                                      }
                                      viewAttributes:{
                                          {@selector(setBackgroundColor:), [UIColor clearColor]},
                                          {@selector(setUserInteractionEnabled:), @NO},
                                      }
                                      size:{}]
                                     ]}
                               }]
                           }, {
                               [CKStackLayoutComponent newWithView:{} size:{} style:{
                                   .direction = CKStackLayoutDirectionVertical,
                                   .alignItems = CKStackLayoutAlignItemsStretch
                               }
                               children:{
                                   {[CKInsetComponent
                                     newWithInsets:{.left = 0, .right = 10, .top = 10, .bottom = 0}
                                     component:
                                       [CKImageComponent newWithImage:[context imageNamed:@"image_quote"] size:{
                                           .height = 27,
                                           .width = 27,
                                       }]
                                     ]},
                                   {
                                        .flexGrow = YES,
                                       .component = [CKComponent newWithView:{} size:{}],
                                   }
                               }]
                           }
                       }]
                    }
                }]
             background:
                [CKComponent
                newWithView:{
                    [UIView class],
                    {
                        {@selector(setBackgroundColor:), [UIColor whiteColor]},
                        {@selector(setContentMode:), @(UIViewContentModeScaleAspectFill)},
                        {@selector(setClipsToBounds:), @YES},
                    }
                }
                size:{}]
             ]
        ]
    ];
}

static CKComponent *lineComponent()
{
    return [CKComponent
            newWithView:{
                [UIView class],
                {
                    {@selector(setBackgroundColor:), [UIColor blackColor]},
                }
            }
            size:{.height = 1 / [UIScreen mainScreen].scale}];
}

@end
