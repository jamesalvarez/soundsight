//
//  StartViewController.h
//  Synestheatre
//
//  Created by James on 28/07/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface StartViewController : UIViewController <UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UILabel *selectModeLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

NS_ASSUME_NONNULL_END
