//
//  RSStatusBarAction.h
//  TextBar
//
//  Created by RichS on 12/2/13.
//  Copyright (c) 2013 RichS. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RSStatusBarActionDelegate <NSObject>

@required
-(void)statusBarAction:(id)sender withTag:(id)tag;

@optional

@end

@interface RSStatusBarAction : NSObject

@property (atomic, weak) id<RSStatusBarActionDelegate> delegate;
@property (atomic, weak) id tag;

+(RSStatusBarAction*)instanceWithDelegate:(id<RSStatusBarActionDelegate>)delegate andTag:(id)tag;
-(id)initWithDelegate:(id)delegate andTag:(id<RSStatusBarActionDelegate>)tag;

- (void)statusBarAction:(id)sender;

@end
