//
//  OperationView.h
//  Conductor
//
//  Created by Andrew Smith on 3/21/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OperationView : UIView

@property (nonatomic, assign) NSUInteger numberOfOperationViews;

@property (nonatomic, strong) NSMutableArray *operationViews;

- (void)addOperationViews;

- (UIView *)operationViewAtIndex:(NSUInteger)index;

- (void)reset;

@end
