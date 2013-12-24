//
//  CDOperationQueueMaxTests.m
//  Conductor
//
//  Created by Andrew Smith on 9/22/12.
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
