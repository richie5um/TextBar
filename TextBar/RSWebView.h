//
//  RSWebView.h
//  TextBar
//
//  Created by RichS on 27/10/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "RSTextBarItem.h"

@interface RSWebView : WebView <WebFrameLoadDelegate>

@property (assign) bool ignoreMouseInteraction;
@property (weak) NSStatusItem* statusItem;
@property (weak) RSTextBarItem* textBarItem;

@end
