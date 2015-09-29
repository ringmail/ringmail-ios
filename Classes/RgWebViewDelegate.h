//
//  RgWebViewDelegate.h
//  ringmail
//
//  Created by Mike Frager on 9/28/15.
//
//

#import <Foundation/Foundation.h>
#import "SVWebViewController.h"

@interface RgWebViewDelegate : NSObject <UIWebViewDelegate>
{
}
@property (weak, nonatomic) SVWebViewController *webView;

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;

@end
