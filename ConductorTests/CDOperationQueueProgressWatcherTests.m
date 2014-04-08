//
//  CDOperationQueueProgressWatcherTests.m
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


#import "CDOperationQueueProgressWatcherTests.h"

#import "CDProgressObserver.h"
#import "CDTestOperation.h"
#import "CDLongRunningTestOperation.h"

@implementation CDOperationQueueProgressWatcherTests

- (void)testCreateWatcher {
    CDProgressObserver *watcher = [CDProgressObserver progressObserverWithStartingOperationCount:10
                                                                                   progressBlock:nil
                                                                              andCompletionBlock:nil];
    
    XCTAssertNotNil(watcher, @"Should create watcher");
    XCTAssertEqual(watcher.startingOperationCount, 10, @"Should have correct number of operations");
}

- (void)testRunWatcherProgressBlock {
    
    __block float progressIndicator = 0.0f;
    
    CDProgressObserverProgressBlock progressBlock = ^(CGFloat progress) {
        progressIndicator = progress;
    };
    
    CDProgressObserver *watcher = [CDProgressObserver progressObserverWithStartingOperationCount:10
                                                                                   progressBlock:progressBlock
                                                                              andCompletionBlock:nil];
    
    [watcher runProgressBlockWithCurrentOperationCount:@1];
    
    XCTAssertEqualWithAccuracy(progressIndicator, 0.9f, 0.000001f, @"Progress block should run correctly");
}

- (void)testRunWatcherCompletionBlock {
    
    __block BOOL completionBlockDidRun = NO;
    
    CDProgressObserverCompletionBlock completionBlock = ^(void) {
        completionBlockDidRun = YES;
    };
    
    CDProgressObserver *watcher = [CDProgressObserver progressObserverWithStartingOperationCount:10
                                                                                   progressBlock:nil
                                                                              andCompletionBlock:completionBlock];
    
    [watcher runCompletionBlock];
    
    XCTAssertTrue(completionBlockDidRun, @"Completion block should run correctly");
}

- (void)testStartingOperationCount
{
    CDLongRunningTestOperation *op1 = [CDLongRunningTestOperation new];
    CDLongRunningTestOperation *op2 = [CDLongRunningTestOperation new];    
    CDLongRunningTestOperation *op3 = [CDLongRunningTestOperation new];    
    
    [testOperationQueue addOperation:op1];
    [testOperationQueue addOperation:op2];
    [testOperationQueue addOperation:op3];
    
    CDProgressObserver *observer = [CDProgressObserver new];
    
    [testOperationQueue addProgressObserver:observer];
    
    NSArray *watchers = [[testOperationQueue progressObservers] allObjects];
    CDProgressObserver *watcher = (CDProgressObserver *)watchers[0];
    
    XCTAssertEqual(watcher.startingOperationCount, 3, @"Progress watcher should have correct starting operation count");    
}

- (void)testAddToStartingOperationCount
{
    CDLongRunningTestOperation *op1 = [CDLongRunningTestOperation longRunningOperationWithDuration:1.0];
    CDLongRunningTestOperation *op2 = [CDLongRunningTestOperation longRunningOperationWithDuration:1.0];    
    CDLongRunningTestOperation *op3 = [CDLongRunningTestOperation longRunningOperationWithDuration:1.0];    
    CDLongRunningTestOperation *op4 = [CDLongRunningTestOperation longRunningOperationWithDuration:1.0];    

    [testOperationQueue addOperation:op1];
    [testOperationQueue addOperation:op2];
    [testOperationQueue addOperation:op3];
    
    CDProgressObserver *observer = [CDProgressObserver new];
    
    [testOperationQueue addProgressObserver:observer];

    [testOperationQueue addOperation:op4];
    
    NSArray *watchers = [[testOperationQueue progressObservers] allObjects];
    CDProgressObserver *watcher = (CDProgressObserver *)watchers[0];
    
    XCTAssertEqual(watcher.startingOperationCount, 4, @"Progress watcher should have correct starting operation count");    
}

- (void)testRunWatcherProgressAndCompletionBlocks
{
    CDTestOperation *op1 = [CDTestOperation new];
    CDTestOperation *op2 = [CDTestOperation new];
    CDTestOperation *op3 = [CDTestOperation new];
    
    [testOperationQueue addOperation:op1];
    [testOperationQueue addOperation:op2];
    [testOperationQueue addOperation:op3];
    
    __block float progressIndicator = 0.0f;
    
    CDProgressObserverProgressBlock progressBlock = ^(CGFloat progress) {
        progressIndicator = progress;
    };
    
    __block BOOL completionBlockDidRun = NO;
    
    CDProgressObserverCompletionBlock completionBlock = ^(void) {
        completionBlockDidRun = YES;
    };
    
    CDProgressObserver *observer = [CDProgressObserver new];

    observer.progressBlock = progressBlock;
    observer.completionBlock = completionBlock;
    
    [testOperationQueue addProgressObserver:observer];
    
    WAIT_ON_BOOL(!testOperationQueue.isExecuting);
    
    XCTAssertTrue(completionBlockDidRun, @"Completion block should run");
    XCTAssertEqual(progressIndicator, 1.0f, @"Progress block should run correctly");
}

@end
