//
//  OperationViewController.h
//  Conductor
//
//  Created by Andrew Smith on 3/21/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OperationView.h"

@interface OperationViewController : UIViewController

@property (nonatomic, strong) IBOutlet OperationView *leftOperationView;

@property (nonatomic, strong) IBOutlet OperationView *rightOperationView;

@property (nonatomic, strong) NSMutableArray *leftSideOperations;

@property (nonatomic, strong) NSMutableArray *rightSideOperations;

@end
