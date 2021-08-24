//
//  ConfigTableViewCell.h
//  Synestheatre
//
//  Created by James on 30/08/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Configuration.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConfigCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView* iconImageView;
@property (weak, nonatomic) IBOutlet UILabel* nameLabel;
@property (weak, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView* frameView;
@property (weak, nonatomic) IBOutlet UIImageView* statusView;
@property (weak, nonatomic) Configuration* config;

- (void)setColor:(UIColor*)color;

@end


NS_ASSUME_NONNULL_END
