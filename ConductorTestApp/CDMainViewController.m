//
//  ViewController.m
//  ConductorApp
//
//  Created by Andrew Smith on 12/12/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import "CDMainViewController.h"
#import "CDSuperLongTaskOperation.h"
#import "CDIsExecutingQueryOperation.h"

#import "AppDelegate.h"

@implementation CDMainViewController

- (IBAction)runLongTask:(id)sender
{
    CDSuperLongTaskOperation *operation1 = [CDSuperLongTaskOperation new];

    [[CDQueueController sharedInstance] addOperation:operation1
                                        toQueueNamed:CONDUCTOR_APP_QUEUE];
}

- (IBAction)runIsExecutingTasks:(id)sender
{
    for (int i = 0; i < 100; i++) {
        CDIsExecutingQueryOperation *op = [CDIsExecutingQueryOperation operationWithRandomNumCycles];
        [[CDQueueController sharedInstance] addOperation:op
                                            toQueueNamed:CONDUCTOR_NONCON_APP_QUEUE];
    }
}

- (IBAction)runAndCancel:(id)sender
{
    for (int i = 0; i < 100; i++){
        CDSuperLongTaskOperation *op = [CDSuperLongTaskOperation new];
        op.identifier = [NSString stringWithFormat:@"%i", i];
        
        __weak CDSuperLongTaskOperation *weakOp = op;
        op.completionBlock = ^{
            __strong CDSuperLongTaskOperation *strongOp = weakOp;
            NSLog(@"%@ complete", strongOp.identifier);
        };
        
        [[CDQueueController sharedInstance] addOperation:op
                                            toQueueNamed:CONDUCTOR_APP_QUEUE];
    }
    
    [[CDQueueController sharedInstance] cancelAllOperations];
}

@end
