//
//  CDOperationQueueTests.m
//  Conductor
//
//  Created by Andrew Smith on 5/2/12.
//  Copyright (c) 2012 Andrew B. Smith ( http://github.com/drewsmits ). All rights reserved.
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


#import "CDOperationQueueTests.h"

#import "CDOperation.h"
#import "CDTestOperation.h"
#import "CDLongRunningTestOperation.h"

@implementation CDOperationQueueTests

- (void)testCreateQueueWithName
{
    CDOperationQueue *queue = [CDOperationQueue queueWithName:@"MyQueueName"];
    XCTAssertEqualObjects(queue.name, @"MyQueueName", @"Queue should have the correct name");
}

- (void)testAddNonCDOperationToQueue
{
    CDOperation *op = (CDOperation *)[NSOperation new];
    XCTAssertThrows([testOperationQueue addOperation:op], @"Adding a non CDOperation subclass should raise an exception");
}

- (void)testAddOperationToQueue
{    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        hasFinished = YES;
    };
    
    CDTestOperation *op = [CDTestOperation new];
    op.completionBlock = completionBlock;
    
    [testOperationQueue addOperation:op];
    
    WAIT_ON_BOOL(!testOperationQueue.isExecuting);
    
    XCTAssertTrue(hasFinished, @"Test operation queue should finish");
}

- (void)testAddOperationToQueueWithDuplicateIdentifier
{    
    CDTestOperation *op1 = [CDTestOperation operationWithIdentifier:@"anIdentifier"];
    CDTestOperation *op2 = [CDTestOperation operationWithIdentifier:@"anIdentifier"];
    
    [testOperationQueue addOperation:op1];
    [testOperationQueue addOperation:op2];
    
    XCTAssertEqualObjects(op1.identifier, @"anIdentifier", @"First operation should have same identifier");
    
    BOOL notEqual = [op1.identifier isEqual:op2.identifier];
    
    XCTAssertFalse(notEqual, @"Second operation should have a different ID");
}

- (void)testAddOperationToQueueAtPriority
{    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        hasFinished = YES;
    };
    
    CDTestOperation *op = [CDTestOperation new];
    op.completionBlock = completionBlock;
    op.queuePriority = NSOperationQueuePriorityVeryLow;
    
    [testOperationQueue addOperation:op];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.2];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    XCTAssertEqual(op.queuePriority, NSOperationQueuePriorityVeryLow, @"Operation should have correct priority");
}

- (void)testChangeOperationPriority
{    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        hasFinished = YES;        
    };
    
    CDTestOperation *op = [CDTestOperation new];
    op.completionBlock = completionBlock;

    [testOperationQueue addOperation:op];

    [testOperationQueue updatePriorityOfOperationWithIdentifier:op.identifier 
                                                  toNewPriority:NSOperationQueuePriorityVeryLow];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.2];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    } 
    
    XCTAssertEqual(op.queuePriority, NSOperationQueuePriorityVeryLow, @"Operation should have correct priority");
}

- (void)testChangeOperationPriorityFinishOrder
{    
    __block BOOL hasFinished = NO;
    
    __block NSDate *last = nil;
    __block NSDate *first = nil;
    
    void (^finishLastBlock)(void) = ^(void) {
        hasFinished = YES;
        last = [NSDate date];
    };
    
    void (^finishFirstBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            first = [NSDate date];
        });
    };    
    
    CDTestOperation *finishLast = [CDTestOperation operationWithIdentifier:@"1"];
    finishLast.completionBlock = finishLastBlock;
    
    CDTestOperation *op = [CDTestOperation operationWithIdentifier:@"2"];
    
    CDTestOperation *finishFirst = [CDTestOperation operationWithIdentifier:@"3"];
    finishFirst.completionBlock = finishFirstBlock;
    
    // pause queue to add operations first, so they dont finish too fast
    [testOperationQueue setSuspended:YES];
    
    [testOperationQueue addOperation:finishLast];
    [testOperationQueue addOperation:op];
    [testOperationQueue addOperation:finishFirst];
    
    [testOperationQueue updatePriorityOfOperationWithIdentifier:@"3" 
                                                  toNewPriority:NSOperationQueuePriorityVeryHigh];
    
    [testOperationQueue updatePriorityOfOperationWithIdentifier:@"1" 
                                                  toNewPriority:NSOperationQueuePriorityVeryLow];
    
    // Resume queue now that stuff is added and operations are in
    [testOperationQueue setSuspended:NO];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.2];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    float firstInt = [first timeIntervalSinceNow];
    float lastInt  = [last timeIntervalSinceNow];
    
    XCTAssertTrue((firstInt < lastInt), @"Operation should finish first");
}

- (void)testEmptyQueueShouldHaveEmptyOperationsDict
{    
    __block BOOL hasFinished = NO;
    
    CDTestOperation *op = [CDTestOperation new];
    
    CDProgressObserver *observer = [CDProgressObserver progressObserverWithStartingOperationCount:0
                                                                                    progressBlock:nil
                                                                               andCompletionBlock:^ {
                                                                                   hasFinished = YES;
                                                                               }];
    [testOperationQueue addProgressObserver:observer];
    
    [testOperationQueue addOperation:op];
    
    WAIT_ON_BOOL(hasFinished);
    
    XCTAssertEqual([testOperationQueue operationCount], 0U, @"Operation queue should be empty");
}

#pragma mark - Operation Count

- (void)testOperationCountNoQueue
{
    XCTAssertEqual(testOperationQueue.operationCount, 0U, @"Operation count should be correct");
}

- (void)testOperationCountQueue
{
    CDLongRunningTestOperation *op1 = [CDLongRunningTestOperation new];
    CDLongRunningTestOperation *op2 = [CDLongRunningTestOperation new];    
    CDLongRunningTestOperation *op3 = [CDLongRunningTestOperation new];    

    [testOperationQueue addOperation:op1];
    [testOperationQueue addOperation:op2];
    [testOperationQueue addOperation:op3];

    XCTAssertEqual(testOperationQueue.operationCount, 3U, @"Operation count should be correct");
}

- (void)testOperationCountAfterOperationFinishes
{    
    CDTestOperation *op = [CDTestOperation new];
    
    [testOperationQueue addOperation:op];
    
    XCTAssertTrue(testOperationQueue.isExecuting, @"Operation queue should be running");
    
    WAIT_ON_BOOL(!testOperationQueue.isExecuting)
    
    XCTAssertEqual(testOperationQueue.operationCount, 0U, @"Operation count should be correct");
}

#pragma mark - State

- (void)testOperationQueueShouldReportExecuting {
    
    CDTestOperation *op = [CDTestOperation new];
    
    [testOperationQueue addOperation:op];
    
    XCTAssertTrue(testOperationQueue.isExecuting, @"Operation queue should be running");
    
    WAIT_ON_BOOL(!testOperationQueue.isExecuting)
    
    XCTAssertFalse(testOperationQueue.isExecuting, @"Operation queue should not be running");
}

- (void)testOperationQueueShouldReportFinished
{    
    CDTestOperation *op = [CDTestOperation new];
    [testOperationQueue addOperation:op];
        
    XCTAssertFalse(testOperationQueue.isFinished, @"Operation queue should not be finished");

    WAIT_ON_BOOL(!testOperationQueue.isExecuting)
    
    XCTAssertTrue(testOperationQueue.isFinished, @"Operation queue should be finished");
}

- (void)testOperationQueueShouldReportSuspended
{
    CDLongRunningTestOperation *op = [CDLongRunningTestOperation new];    
    [testOperationQueue addOperation:op];
    
    XCTAssertFalse(testOperationQueue.isSuspended, @"Operation queue should not be suspended");
    
    [testOperationQueue setSuspended:YES];
    
    XCTAssertTrue(testOperationQueue.isSuspended, @"Operation queue should be finished");
}

- (void)testOperationQueueShouldResumeAfterSuspended
{
    CDLongRunningTestOperation *op = [CDLongRunningTestOperation longRunningOperationWithDuration:5.0];
    [testOperationQueue addOperation:op];
    
    [testOperationQueue setSuspended:YES];
    [testOperationQueue setSuspended:NO];

    XCTAssertTrue(testOperationQueue.isExecuting, @"Operation queue should be executing");
}

@end
