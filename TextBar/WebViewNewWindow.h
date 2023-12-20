//
//  WebViewNewWindow.h
//  TextBar
//
//  Created by RichS on 16/01/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface WebViewNewWindow : NSObject <WebPolicyDelegate, WebUIDelegate>

+(WebViewNewWindow*)instance;
-(WebView*)newWebView;

@end
