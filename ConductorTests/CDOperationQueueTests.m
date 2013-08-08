//
//  CDOperationQueueTests.m
//  Conductor
//
//  Created by Andrew Smith on 5/2/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import "CDOperationQueueTests.h"

#import "CDOperation.h"
#import "CDTestOperation.h"
#import "CDLongRunningTestOperation.h"

@implementation CDOperationQueueTests

- (void)testCreateQueueWithName
{
    CDOperationQueue *queue = [CDOperationQueue queueWithName:@"MyQueueName"];
    STAssertEqualObjects(queue.name, @"MyQueueName", @"Queue should have the correct name");
}

- (void)testAddNonCDOperationToQueue
{
    CDOperation *op = (CDOperation *)[NSOperation new];
    STAssertThrows([testOperationQueue addOperation:op], @"Adding a non CDOperation subclass should raise an exception");
}

- (void)testAddOperationToQueue
{    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;        
        });
    };         
    
    CDTestOperation *op = [CDTestOperation new];
    op.completionBlock = completionBlock;
    
    [testOperationQueue addOperation:op];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.2];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    STAssertTrue(hasFinished, @"Test operation queue should finish");
}

- (void)testAddOperationToQueueWithDuplicateIdentifier
{    
    CDTestOperation *op1 = [CDTestOperation operationWithIdentifier:@"anIdentifier"];
    CDTestOperation *op2 = [CDTestOperation operationWithIdentifier:@"anIdentifier"];
    
    [testOperationQueue addOperation:op1];
    [testOperationQueue addOperation:op2];
    
    STAssertEqualObjects(op1.identifier, @"anIdentifier", @"First operation should have same identifier");
    
    BOOL notEqual = [op1.identifier isEqual:op2.identifier];
    
    STAssertFalse(notEqual, @"Second operation should have a different ID");
}

- (void)testAddOperationToQueueAtPriority
{    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;        
        });
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
    
    STAssertEquals(op.queuePriority, NSOperationQueuePriorityVeryLow, @"Operation should have correct priority");
}

- (void)testChangeOperationPriority
{    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;        
        });
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
    
    STAssertEquals(op.queuePriority, NSOperationQueuePriorityVeryLow, @"Operation should have correct priority");
}

- (void)testChangeOperationPriorityFinishOrder
{    
    __block BOOL hasFinished = NO;
    
    __block NSDate *last = nil;
    __block NSDate *first = nil;
    
    void (^finishLastBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;
            last = [NSDate date];
        });
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
    
    STAssertTrue((firstInt < lastInt), @"Operation should finish first");
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
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    STAssertEquals([testOperationQueue operationCount], 0U, @"Operation queue should be empty");
}

#pragma mark - Operation Count

- (void)testOperationCountNoQueue
{
    STAssertEquals(testOperationQueue.operationCount, 0U, @"Operation count should be correct");
}

- (void)testOperationCountQueue
{
    CDLongRunningTestOperation *op1 = [CDLongRunningTestOperation new];
    CDLongRunningTestOperation *op2 = [CDLongRunningTestOperation new];    
    CDLongRunningTestOperation *op3 = [CDLongRunningTestOperation new];    

    [testOperationQueue addOperation:op1];
    [testOperationQueue addOperation:op2];
    [testOperationQueue addOperation:op3];

    STAssertEquals(testOperationQueue.operationCount, 3U, @"Operation count should be correct");
}

- (void)testOperationCountAfterOperationFinishes
{    
    CDTestOperation *op = [CDTestOperation new];
    
    [testOperationQueue addOperation:op];
    
    STAssertTrue(testOperationQueue.isExecuting, @"Operation queue should be running");
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.2];
    while (testOperationQueue.isExecuting) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    STAssertEquals(testOperationQueue.operationCount, 0U, @"Operation count should be correct");
}

#pragma mark - State

- (void)testOperationQueueShouldReportExecuting {
    
    CDTestOperation *op = [CDTestOperation new];
    
    [testOperationQueue addOperation:op];
    
    STAssertTrue(testOperationQueue.isExecuting, @"Operation queue should be running");
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.2];
    while (testOperationQueue.isExecuting) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    STAssertFalse(testOperationQueue.isExecuting, @"Operation queue should not be running");
}

- (void)testOperationQueueShouldReportFinished
{    
    CDTestOperation *op = [CDTestOperation new];
    [testOperationQueue addOperation:op];
        
    STAssertFalse(testOperationQueue.isFinished, @"Operation queue should not be finished");

    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.2];
    while (testOperationQueue.isExecuting) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    STAssertTrue(testOperationQueue.isFinished, @"Operation queue should be finished");
}

- (void)testOperationQueueShouldReportSuspended
{
    CDLongRunningTestOperation *op = [CDLongRunningTestOperation new];    
    [testOperationQueue addOperation:op];
    
    STAssertFalse(testOperationQueue.isSuspended, @"Operation queue should not be suspended");
    
    [testOperationQueue setSuspended:YES];
    
    STAssertTrue(testOperationQueue.isSuspended, @"Operation queue should be finished");
}

- (void)testOperationQueueShouldResumeAfterSuspended
{
    CDLongRunningTestOperation *op = [CDLongRunningTestOperation longRunningOperationWithDuration:5.0];
    [testOperationQueue addOperation:op];
    
    [testOperationQueue setSuspended:YES];
    [testOperationQueue setSuspended:NO];

    STAssertTrue(testOperationQueue.isExecuting, @"Operation queue should be executing");
}

#pragma mark - Progress

@end
