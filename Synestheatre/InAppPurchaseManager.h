//
//  InAppPurchaseManager.h
//  Synestheatre
//
//  Created by James on 25/10/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "IAPHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface InAppPurchaseManager : IAPHelper

+ (InAppPurchaseManager *)sharedInstance;

@end

NS_ASSUME_NONNULL_END
