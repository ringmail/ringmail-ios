//
//  RgWebViewDelegate.m
//  ringmail
//
//  Created by Mike Frager on 9/28/15.
//
//

#import "RgWebViewDelegate.h"
#import "RegexKitLite/RegexKitLite.h"
#import "RgManager.h"

@implementation RgWebViewDelegate
@synthesize webView = _webView;

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //NSLog(@"RingMail: WebView Loading URL: %@", request.URL.absoluteString);
    NSString *url = request.URL.absoluteString;
    if ([url isMatchedByRegex:@"^ring:"])
    {
        NSLog(@"RingMail: WebView Ring URL: %@", url);
        [_webView dismissViewControllerAnimated:YES completion:NULL];
        [RgManager processRingURI:url];
        return NO;
    }
    //return FALSE; //to stop loading
    return YES;
}

@end
