//
//  OperationViewController.m
//  Conductor
//
//  Created by Andrew Smith on 3/21/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

/**
 When the view loads, hit Start. This creates 56 CDOperations that will execute for one second each.
 The operations are split up into two groups, the left side and the right side, and added to the same
 serial queue. When a left side operation finishes, it changes the next grid item to green. If it is
 canceled, it changes the grid item to red. The operations are added to the serial queue such that
 the operations alternate left and right sides to allow you to play around with changing priorities.
 */

#import "OperationViewController.h"
#import "CDOneSecondOperation.h"

#define NUMBER_OF_OPERATIONS_PER_SIDE 28

@implementation OperationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    CDProgressObserver *observer = [CDProgressObserver new];
    
    observer.progressBlock = ^(CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Makin progress: %f", progress);            
        });
    };
    
    observer.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"I'm done");
        });
    };
    
    // Left side
    self.leftSideOperations = [NSMutableArray new];
    self.leftOperationView.numberOfOperationViews = NUMBER_OF_OPERATIONS_PER_SIDE;
    [self.leftOperationView addOperationViews];
    [self.leftOperationView setNeedsLayout];
    
    // Right side
    self.rightSideOperations = [NSMutableArray new];
    self.rightOperationView.numberOfOperationViews = NUMBER_OF_OPERATIONS_PER_SIDE;
    [self.rightOperationView addOperationViews];
    [self.rightOperationView setNeedsLayout];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[CDQueueController sharedInstance] cancelAllOperations];
}

#pragma mark - IBAction

- (IBAction)start:(id)sender
{
    //
    // Before you start again, cancel all operations
    //
    [[CDQueueController sharedInstance] cancelAllOperations];
    
    //
    // Reset the views that have already run. Notice that the canceled operations will run their
    // completion block after the reset happens.
    //
    [self.leftOperationView reset];
    [self.rightOperationView reset];
    
    //
    // Remove all operations
    //
    [self.leftSideOperations removeAllObjects];
    [self.rightSideOperations removeAllObjects];
    
    NSUInteger totalOperations = 2 * NUMBER_OF_OPERATIONS_PER_SIDE;
    NSUInteger index = 0;
    
    for (int i = 0; i < totalOperations; i++) {
        CDOneSecondOperation *operation = [CDOneSecondOperation new];
        operation.identifier = [NSString stringWithFormat:@"%i", i];
        
        /**
         - Alernate adding operations to the left and the right.
         - Set the completion block to change the view to green if finished, red if canceled
         */
        
        BOOL even = (i % 2 == 0);
        
        // Prevent retain cycle
        __weak CDOneSecondOperation *weakOp = operation;

        if (even) {
            operation.completionBlock = ^{
                __strong CDOneSecondOperation *strongOp = weakOp;
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIView *view = [self.leftOperationView operationViewAtIndex:index];
                    if (strongOp.isCancelled) {
                        view.backgroundColor = [UIColor redColor];
                    } else {
                        view.backgroundColor = [UIColor greenColor];
                    }
                });
            };
            [self.leftSideOperations addObject:operation];
        } else {
            operation.completionBlock = ^{
                __strong CDOneSecondOperation *strongOp = weakOp;
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIView *view = [self.rightOperationView operationViewAtIndex:index];
                    if (strongOp.isCancelled) {
                        view.backgroundColor = [UIColor redColor];
                    } else {
                        view.backgroundColor = [UIColor greenColor];
                    }
                });
            };
            [self.rightSideOperations addObject:operation];
            index += 1;
        }
        
        //
        // Add the operation to the queue, which effectively will start it
        //
        [[CDQueueController sharedInstance] addOperation:operation toQueueNamed:CONDUCTOR_APP_QUEUE];
    }
}

- (IBAction)cancel:(id)sender
{
    /**
     Notice that cancel will flush out all the operations and cause the completionBlock to run. In our
     case, inside the completion block we check to see if the operation was canceled and act accodringly
     */
    [[CDQueueController sharedInstance] cancelAllOperations];
}

- (IBAction)pause:(id)sender
{
    [[CDQueueController sharedInstance] suspendAllQueues];
}

- (IBAction)resume:(id)sender
{
    [[CDQueueController sharedInstance] resumeAllQueues];
}

#pragma mark - Priority

- (IBAction)increasePriorityOfLeft
{
    /**
     This sets the left side operations to NSOperationQueuePriorityHigh.
     
     You have to downgrade the priority of the operations you don't want to run anymore. Notice that
     this shuffles the operations execution order permanently. If you set all operations back to normal,
     it would have some new order, where operations not at normal are stacked below operations that
     are already normal.
     */
    [self resetPriorityOfRight];
    
    for (CDOperation *operation in self.leftSideOperations) {
        [[CDQueueController sharedInstance] updatePriorityOfOperationWithIdentifier:operation.identifier
                                                                       inQueueNamed:CONDUCTOR_APP_QUEUE
                                                                      toNewPriority:NSOperationQueuePriorityHigh];
    }
}

- (IBAction)resetPriorityOfLeft
{
    for (CDOperation *operation in self.leftSideOperations) {
        [[CDQueueController sharedInstance] updatePriorityOfOperationWithIdentifier:operation.identifier
                                                                       inQueueNamed:CONDUCTOR_APP_QUEUE
                                                                      toNewPriority:NSOperationQueuePriorityNormal];
    }
}

- (IBAction)increasePriorityOfRight
{
    [self resetPriorityOfLeft];
    
    for (CDOperation *operation in self.rightSideOperations) {
        [[CDQueueController sharedInstance] updatePriorityOfOperationWithIdentifier:operation.identifier
                                                                       inQueueNamed:CONDUCTOR_APP_QUEUE
                                                                      toNewPriority:NSOperationQueuePriorityHigh];
    }
}

- (IBAction)resetPriorityOfRight
{
    for (CDOperation *operation in self.rightSideOperations) {
        [[CDQueueController sharedInstance] updatePriorityOfOperationWithIdentifier:operation.identifier
                                                                       inQueueNamed:CONDUCTOR_APP_QUEUE
                                                                      toNewPriority:NSOperationQueuePriorityNormal];
    }
}

@end
