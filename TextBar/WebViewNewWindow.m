//
//  WebViewNewWindow.m
//  TextBar
//
//  Created by RichS on 16/01/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "WebViewNewWindow.h"
#import <WebKit/WebKit.h>

@implementation WebViewNewWindow

//-------------------------------------------------------------------------//
+(WebViewNewWindow*)instance {
    return [[WebViewNewWindow alloc] init];
}

//-------------------------------------------------------------------------//
-(WebViewNewWindow*)init {
    if ( nil != (self = [super init])) {
    }
    
    return self;
}

//-------------------------------------------------------------------------//
-(WebView*)newWebView {
    WebView* webView = [[WebView alloc] init];
    [webView setUIDelegate:self];
    [webView setPolicyDelegate:self];

    return webView;
}

//-------------------------------------------------------------------------//
-(void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    [[NSWorkspace sharedWorkspace] openURL:[actionInformation objectForKey:WebActionOriginalURLKey]];
}

@end
