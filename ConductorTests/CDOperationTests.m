//
//  CDOperationTests.m
//  Conductor
//
//  Created by Andrew Smith on 5/2/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import "CDOperationTests.h"

#import "CDOperation.h"
#import "CDTestOperation.h"

@implementation CDOperationTests

- (void)testCreateOperationWithIdentifier
{
    CDOperation *op = [CDOperation operationWithIdentifier:@"1234"];
    XCTAssertEqualObjects(op.identifier, @"1234", @"Operation should have correct identifier");
}

- (void)testCreateOperationWithoutIdentifier
{
    CDOperation *op = [CDOperation new];
    XCTAssertNotNil(op.identifier, @"Operation should have an auto generated identifier");
}

- (void)testRunTestOperation
{    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;        
        });
    };         
    
    CDTestOperation *op = [CDTestOperation new];
    op.completionBlock = completionBlock;
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:op];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.2];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    XCTAssertTrue(hasFinished, @"Test operation should run");
    XCTAssertTrue(op.isFinished, @"Test operation should be finished");
}

//- (void)testCancelOperation
//{    
//    CDTestOperation *op = [CDTestOperation new];
//    
//    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
//    [queue addOperation:op];
//    [queue cancelAllOperations];
//    
//    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.2];
//    while (queue.operationCount == 0) {
//        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
//                                 beforeDate:loopUntil];
//    }    
//    
//    XCTAssertTrue(op.isCancelled, @"Test operation should be cancelled");
//}

@end
