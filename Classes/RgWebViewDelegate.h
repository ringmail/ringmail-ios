//
//  RgWebViewDelegate.h
//  ringmail
//
//  Created by Mike Frager on 9/28/15.
//
//

#import <Foundation/Foundation.h>
#import "SVModalWebViewController.h"

@interface RgWebViewDelegate : NSObject<UIWebViewDelegate>
{
}
@property (weak, nonatomic) SVModalWebViewController *webView;
@end
