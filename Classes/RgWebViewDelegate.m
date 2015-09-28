//
//  RgWebViewDelegate.m
//  ringmail
//
//  Created by Mike Frager on 9/28/15.
//
//

#import "RgWebViewDelegate.h"

@implementation RgWebViewDelegate
@synthesize webView;

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"Loading URL: %@", request.URL.absoluteString);
    
    //return FALSE; //to stop loading
    return YES;
}

@end
