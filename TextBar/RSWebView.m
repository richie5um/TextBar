//
//  RSWebView.m
//  TextBar
//
//  Created by RichS on 27/10/2017.
//  Copyright © 2017 RichS. All rights reserved.
//

#import "RSWebView.h"

@implementation RSWebView

//-------------------------------------------------------------------------//
- (instancetype)initWithFrame:(NSRect)frameRect {
    if ( nil != (self = [super initWithFrame:frameRect])) {
        [self setFrameLoadDelegate:self];
    }
    
    return self;
}

//-------------------------------------------------------------------------//
-(NSView *)hitTest:(NSPoint)point {
    if (self.ignoreMouseInteraction) {
//        NSLog(@"WebView HitTest: %@", NSStringFromPoint(point));

        // Return the next responder to ignore mouse interactions
        return (NSView*)[self nextResponder];
    } else {
        return [super hitTest:point];
    }
}

//-------------------------------------------------------------------------//
- (void)webViewDidFinishLoad:(WebView*)webView {
    NSLog(@"WebViewDidFinishLoad");
}

//-------------------------------------------------------------------------//
- (void)consoleLog:(NSString *)aMessage {
    NSLog(@"JSLog: %@", aMessage);
}

//-------------------------------------------------------------------------//
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
    if (aSelector == @selector(consoleLog:)) {
        return NO;
    }
    
    return YES;
}

//-------------------------------------------------------------------------//
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if (frame == [frame findFrameNamed:@"_top"]) {
        WebScriptObject* scriptObject = [sender windowScriptObject];
        [scriptObject setValue:self forKey:@"MyApp"];
        
        [scriptObject evaluateWebScript:@"console = { log: function(msg) { MyApp.consoleLog_(msg); }, error: function(msg) { MyApp.consoleLog_(msg); } }; window.onerror = function(message, url, lineNumber) {console.error('Error @ Line: ' + lineNumber); console.error(message); return false; }; if (typeof JSON.decycle !== 'function') { JSON.decycle = function decycle(object, replacer) { 'use strict'; var objects = new WeakMap(); return (function derez(value, path) { var old_path; var nu; if (replacer !== undefined) { value = replacer(value); } if ( typeof value === 'object' && value !== null && !(value instanceof Boolean) && !(value instanceof Date) && !(value instanceof Number) && !(value instanceof RegExp) && !(value instanceof String) ) { old_path = objects.get(value); if (old_path !== undefined) { return {$ref: old_path}; } objects.set(value, path); if (Array.isArray(value)) { nu = []; value.forEach(function (element, i) { nu[i] = derez(element, path + '[' + i + ']'); }); } else { nu = {}; Object.keys(value).forEach(function (name) { nu[name] = derez( value[name], path + '[' + JSON.stringify(name) + ']' ); }); } return nu; } return value; }(object, '$')); };}if (typeof JSON.retrocycle !== 'function') { JSON.retrocycle = function retrocycle($) { 'use strict'; var px = /^\\$(?:\[(?:\\d+|'(?:[^\\'\\u0000-\\u001f]|\\([\\'\\/bfnrt]|u[0-9a-zA-Z]{4}))*')\\])*$/; (function rez(value) { if (value && typeof value === 'object') { if (Array.isArray(value)) { value.forEach(function (element, i) { if (typeof element === 'object' && element !== null) { var path = element.$ref; if (typeof path === 'string' && px.test(path)) { value[i] = eval(path); } else { rez(element); } } }); } else { Object.keys(value).forEach(function (name) { var item = value[name]; if (typeof item === 'object' && item !== null) { var path = item.$ref; if (typeof path === 'string' && px.test(path)) { value[name] = eval(path); } else { rez(item); } } }); } } }($)); return $; }; }"];

//        [scriptObject evaluateWebScript:@"console = { log: function(msg) { MyApp.consoleLog_(msg); }, error: function(msg) { MyApp.consoleLog_(msg); } };"];
//        [scriptObject evaluateWebScript:@"window.onerror = function(message, url, lineNumber) {console.error('Error @ Line: ' + lineNumber); console.error(message); return false; };"];
//
//        [scriptObject evaluateWebScript:@"if (typeof JSON.decycle !== 'function') { JSON.decycle = function decycle(object, replacer) { 'use strict'; var objects = new WeakMap(); return (function derez(value, path) { var old_path; var nu; if (replacer !== undefined) { value = replacer(value); } if ( typeof value === 'object' && value !== null && !(value instanceof Boolean) && !(value instanceof Date) && !(value instanceof Number) && !(value instanceof RegExp) && !(value instanceof String) ) { old_path = objects.get(value); if (old_path !== undefined) { return {$ref: old_path}; } objects.set(value, path); if (Array.isArray(value)) { nu = []; value.forEach(function (element, i) { nu[i] = derez(element, path + '[' + i + ']'); }); } else { nu = {}; Object.keys(value).forEach(function (name) { nu[name] = derez( value[name], path + '[' + JSON.stringify(name) + ']' ); }); } return nu; } return value; }(object, '$')); };}if (typeof JSON.retrocycle !== 'function') { JSON.retrocycle = function retrocycle($) { 'use strict'; var px = /^\\$(?:\[(?:\\d+|'(?:[^\\'\\u0000-\\u001f]|\\([\\'\\/bfnrt]|u[0-9a-zA-Z]{4}))*')\\])*$/; (function rez(value) { if (value && typeof value === 'object') { if (Array.isArray(value)) { value.forEach(function (element, i) { if (typeof element === 'object' && element !== null) { var path = element.$ref; if (typeof path === 'string' && px.test(path)) { value[i] = eval(path); } else { rez(element); } } }); } else { Object.keys(value).forEach(function (name) { var item = value[name]; if (typeof item === 'object' && item !== null) { var path = item.$ref; if (typeof path === 'string' && px.test(path)) { value[name] = eval(path); } else { rez(item); } } }); } } }($)); return $; }; }"];
    }
}

@end
