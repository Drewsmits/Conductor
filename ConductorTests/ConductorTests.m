//
//  ConductorTests.m
//  ConductorTests
//
//  Created by Andrew Smith on 10/21/11.
//  Copyright (c) 2011 Andrew B. Smith ( http://github.com/drewsmits ). All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal 
// in the Software without restriction, including without limitation the rights 
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
// of the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ConductorTests.h"

#import "Conductor.h"

#import "CDOperation.h"
#import "CDTestOperation.h"
#import "CDLongRunningTestOperation.h"
#import "ConductorTestMacros.h"

@implementation ConductorTests

- (void)testConductorAddOperation {
    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        hasFinished = YES;
    };
    
    CDTestOperation *op = [CDTestOperation new];
    op.completionBlock = completionBlock;
    
    [conductor addOperation:op
               toQueueNamed:CONDUCTOR_TEST_QUEUE];
        
    NSDate *time = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while (!hasFinished) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:time];
    }
    
    XCTAssertTrue(hasFinished, @"Conductor should add and complete test operation");
}

- (void)testConductorAddOperationThreeTimes
{    
    CDLongRunningTestOperation *op1 = [CDLongRunningTestOperation new];
    CDLongRunningTestOperation *op2 = [CDLongRunningTestOperation new];
    CDLongRunningTestOperation *op3 = [CDLongRunningTestOperation new];

    [conductor addOperation:op1 toQueueNamed:CONDUCTOR_TEST_QUEUE];
    [conductor addOperation:op2 toQueueNamed:CONDUCTOR_TEST_QUEUE];
    [conductor addOperation:op3 toQueueNamed:CONDUCTOR_TEST_QUEUE];

    XCTAssertEqual(conductor.queues.count, 1U, @"Conducter should only have one queue");
}

- (void)testConductorUpdateQueuePriority
{
    
}

- (void)testConductorIsExecuting
{    
    CDTestOperation *op = [CDTestOperation new];
    
    [conductor addOperation:op toQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    XCTAssertTrue([conductor isExecuting], @"Conductor should be running");
    
    [conductor waitForQueueNamed:CONDUCTOR_TEST_QUEUE]; 
    
    XCTAssertFalse([conductor isExecuting], @"Conductor should not be executing");
}

- (void)testConducturIsQueueExecutingNamed
{
    CDTestOperation *op = [CDTestOperation new];
    [conductor addOperation:op toQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    BOOL isExecuting = [conductor isQueueExecutingNamed:CONDUCTOR_TEST_QUEUE];
    XCTAssertTrue(isExecuting, @"Queue named should be executing");
    
    [conductor waitForQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    isExecuting = [conductor isQueueExecutingNamed:CONDUCTOR_TEST_QUEUE];
    XCTAssertFalse(isExecuting, @"Queue named should be executing");
}

- (void)testConductorNumberOfOperationsInQueueNamed
{
    CDTestOperation *op = [CDTestOperation new];
    [conductor addOperation:op toQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    NSUInteger num = [conductor numberOfOperationsInQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    XCTAssertEqual(num, 1U, @"Queue should have one executing");
    
    [conductor waitForQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    num = [conductor numberOfOperationsInQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    XCTAssertEqual(num, 0U, @"Queue should have one executing");
}

- (void)testConductorCancelAllOperations {
        
    CDLongRunningTestOperation *op = [CDLongRunningTestOperation new];
    
    [conductor addOperation:op toQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    [conductor cancelAllOperations];
        
    XCTAssertTrue(op.isCancelled, @"Operation should be cancelled");
}

- (void)testConductureCancelAllOperationsInQueueNamed {
    CDLongRunningTestOperation *op = [CDLongRunningTestOperation new];
    
    [conductor addOperation:op toQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    [conductor cancelAllOperationsInQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    XCTAssertTrue(op.isCancelled, @"Operation should be cancelled");
}

- (void)testConductorSuspendAllQueues {
    CDLongRunningTestOperation *op = [CDLongRunningTestOperation new];
    
    [conductor addOperation:op toQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    [conductor suspendAllQueues];
    
    CDOperationQueue *queue = [conductor getQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    XCTAssertTrue(queue.isSuspended, @"Operation queue should be suspended");
}

- (void)testConductorSuspendQueueNamed {
    CDLongRunningTestOperation *op = [CDLongRunningTestOperation new];
    
    [conductor addOperation:op toQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    [conductor suspendQueueNamed:CONDUCTOR_TEST_QUEUE];

    CDOperationQueue *queue = [conductor getQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    XCTAssertTrue(queue.isSuspended, @"Operation queue should be suspended");    
}

- (void)testConductorResumeAllQueues
{    
    __block BOOL hasFinished = NO;
    void (^completionBlock)(void) = ^(void) {
        hasFinished = YES;
    };         
    
    CDLongRunningTestOperation *op = [CDLongRunningTestOperation longRunningOperationWithDuration:1.0];
    op.completionBlock = completionBlock;
    
    [conductor addOperation:op toQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    [conductor suspendAllQueues];
    [conductor resumeAllQueues];
    
    WAIT_ON_BOOL(hasFinished);
    
    XCTAssertTrue(hasFinished, @"Conductor should add and complete test operation");
}

- (void)testConductorResumeQueueNamed
{    
    __block BOOL hasFinished = NO;
    void (^completionBlock)(void) = ^(void) {
        hasFinished = YES;        
    };         
    
    CDLongRunningTestOperation *op = [CDLongRunningTestOperation longRunningOperationWithDuration:1.0];
    op.completionBlock = completionBlock;
    
    [conductor addOperation:op toQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    [conductor suspendQueueNamed:CONDUCTOR_TEST_QUEUE];
    [conductor resumeQueueNamed:CONDUCTOR_TEST_QUEUE];
        
    WAIT_ON_BOOL(hasFinished);
    
    XCTAssertTrue(hasFinished, @"Conductor should add and complete test operation");
}

//- (void)testConductorTryToBreakIt
//{
//    for (int i = 0; i < 50; i++) {
//        CDLongRunningTestOperation *op = [CDLongRunningTestOperation longRunningOperationWithDuration:0.3];
//        
//        op.identifier = [NSString stringWithFormat:@"%i", i];
//        
//        __weak CDLongRunningTestOperation *weakOp = op;
//        op.completionBlock = ^{
//            __strong CDLongRunningTestOperation *strongOp = weakOp;
//            NSLog(@"%@ complete", strongOp.identifier);
//        };
//        
//        [conductor addOperation:op toQueueNamed:CONDUCTOR_TEST_QUEUE];
//    }
//    
//    [conductor cancelAllOperations];
//    
//    __block BOOL completionBlockDidRun = NO;
//    CDProgressObserverCompletionBlock completionBlock = ^(void) {
//        completionBlockDidRun = YES;
//    };
//    
//    __block float queueProgress = 0.0;
//    CDProgressObserverProgressBlock progressBlock = ^(float progress) {
//        queueProgress = progress;
//    };
//    
//    CDProgressObserver *observer = [CDProgressObserver new];
//    
//    observer.progressBlock   = progressBlock;
//    observer.completionBlock = completionBlock;
//    
//    [conductor addProgressObserver:observer
//                      toQueueNamed:CONDUCTOR_TEST_QUEUE];
//    
//    CDLongRunningTestOperation *op = [CDLongRunningTestOperation longRunningOperationWithDuration:1.0];
//    [conductor addOperation:op toQueueNamed:CONDUCTOR_TEST_QUEUE];
//    
//    [conductor waitForQueueNamed:CONDUCTOR_TEST_QUEUE];
//    
//    XCTAssertTrue(completionBlockDidRun, @"Completion block should have run!");
//    XCTAssertEqual(queueProgress, 1.0f, @"Progress should be at 100 percent");
//}

@end
