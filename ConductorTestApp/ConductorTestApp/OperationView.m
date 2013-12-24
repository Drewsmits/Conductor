//
//  OperationView.m
//  Conductor
//
//  Created by Andrew Smith on 3/21/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "OperationView.h"

#define OPERATION_VIEW_SIZE 25.0

@implementation OperationView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _operationViews = [NSMutableArray new];
    }
    return self;
}

- (void)addOperationViews
{
    CGRect operationRect = CGRectMake(0, 0, OPERATION_VIEW_SIZE, OPERATION_VIEW_SIZE);

    for (int i = 0; i < self.numberOfOperationViews; i++) {
        UIView *opView = [[UIView alloc] initWithFrame:operationRect];
        opView.layer.cornerRadius = 4.0;
        opView.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1.0];
        [self.operationViews addObject:opView];
        [self addSubview:opView];
    }
}

- (UIView *)operationViewAtIndex:(NSUInteger)index
{
    if (index > self.operationViews.count) return nil;
    return [self.operationViews objectAtIndex:index];
}

- (void)reset
{
    for (UIView *view in self.operationViews) {
        view.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    }
}

- (void)layoutSubviews
{
    CGFloat padding = 5.0;
    
    // Calculate views per row
    NSUInteger viewsPerRow = (self.frame.size.width - padding) / (OPERATION_VIEW_SIZE + padding);
    
    __block NSUInteger currentRow = 0;
    __block NSUInteger currentColumn = 0;
    
    [self.operationViews enumerateObjectsUsingBlock:^(UIView *opView, NSUInteger idx, BOOL *stop)
    {
        CGFloat x = padding + currentRow * (padding + OPERATION_VIEW_SIZE);
        CGFloat y = padding + currentColumn * (padding + OPERATION_VIEW_SIZE);
        
        opView.frame = CGRectMake(x,
                                  y,
                                  opView.frame.size.width,
                                  opView.frame.size.height);
        
        currentRow += 1;
        
        if (currentRow >= viewsPerRow) {
            currentColumn += 1;
            currentRow = 0;
        }
    }];
}

@end
