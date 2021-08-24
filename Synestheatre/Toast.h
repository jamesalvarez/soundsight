//
//  Toast.h
//  Synestheatre
//
//  Created by James on 01/08/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Toast : NSObject
+ (void)makeToast:(NSString*)msg;
+ (UIViewController *)topViewController;
@end
