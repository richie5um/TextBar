//
//  RSTemporaryDirectory.h
//  TextBar
//
//  Created by RichS on 09/07/2016.
//  Copyright © 2016 RichS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSTemporaryDirectory : NSObject

+(RSTemporaryDirectory*)instance;

@property (atomic, strong) NSURL* directory;

@end
