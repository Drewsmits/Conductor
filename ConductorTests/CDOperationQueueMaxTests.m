//
//  CDOperationQueueMaxTests.m
//  Conductor
//
//  Created by Andrew Smith on 9/22/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import "CDOperationQueueMaxTests.h"

#import "CDOperationQueue.h"
#import "CDTestOperation.h"
#import "CDLongRunningTestOperation.h"

@interface MockQueueObserver : NSObject <CDOperationQueueOperationsObserver>
@property (assign) BOOL maxReachedMessageReceieved;
@property (assign) BOOL canBeginMessageRecieved;
@end

@implementation MockQueueObserver

- (void)maxQueuedOperationsReachedForQueue:(CDOperationQueue *)queue
{
    self.maxReachedMessageReceieved = YES;
}

- (void)canBeginSubmittingOperationsForQueue:(CDOperationQueue *)queue
{
    self.canBeginMessageRecieved = YES;
}

@end

@implementation CDOperationQueueMaxTests

- (void)testMaxQueuedOperations
{
    CDOperationQueue *queue = [CDOperationQueue new];
    [queue setMaxConcurrentOperationCount:1];
    [queue setMaxQueuedOperationsCount:2];
    
    XCTAssertFalse(queue.maxQueueOperationCountReached, @"Max queued operations should not be reached");
    
    [queue addOperation:[CDLongRunningTestOperation longRunningOperationWithDuration:1.0]];
    [queue addOperation:[CDLongRunningTestOperation longRunningOperationWithDuration:1.0]];
    [queue addOperation:[CDLongRunningTestOperation longRunningOperationWithDuration:1.0]];

    XCTAssertTrue(queue.maxQueueOperationCountReached, @"Max queued operations should not be reached");
}

- (void)testSubmitMaxQueuesOperations
{
    CDOperationQueue *queue = [CDOperationQueue new];
    [queue setMaxConcurrentOperationCount:1];
    [queue setMaxQueuedOperationsCount:2];
    
    MockQueueObserver *mockObserver = [MockQueueObserver new];
    queue.operationsObserver = mockObserver;
    
    [queue addOperation:[CDLongRunningTestOperation longRunningOperationWithDuration:1.0]];
    [queue addOperation:[CDLongRunningTestOperation longRunningOperationWithDuration:1.0]];
    [queue addOperation:[CDLongRunningTestOperation longRunningOperationWithDuration:1.0]];
    
    XCTAssertTrue(mockObserver.maxReachedMessageReceieved, @"Observer should have recieved max message");
}

- (void)testCanBeginSubmitting
{
    CDOperationQueue *queue = [CDOperationQueue new];
    [queue setMaxConcurrentOperationCount:1];
    [queue setMaxQueuedOperationsCount:2];
    
    MockQueueObserver *mockObserver = [MockQueueObserver new];
    queue.operationsObserver = mockObserver;
    
    [queue addOperation:[CDTestOperation new]];
    [queue addOperation:[CDTestOperation new]];
    
    // Loop until queue finishes
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:1.0];
    while (queue.isExecuting == YES) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    XCTAssertTrue(mockObserver.canBeginMessageRecieved, @"Observer should have recieved max message");
}


@end
