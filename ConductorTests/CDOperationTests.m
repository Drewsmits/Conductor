//
//  CDOperationTests.m
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
        hasFinished = YES;
    };
    
    CDTestOperation *op = [CDTestOperation new];
    op.completionBlock = completionBlock;
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:op];
    
    WAIT_ON_BOOL(hasFinished);
    
    XCTAssertTrue(hasFinished, @"Test operation should run");
    XCTAssertTrue(op.isFinished, @"Test operation should be finished");
}

- (void)testCancelOperation
{    
    CDTestOperation *op = [CDTestOperation new];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:op];
    [queue cancelAllOperations];
    
    WAIT_ON_BOOL(queue.operationCount == 0);
    
    XCTAssertTrue(op.isCancelled, @"Test operation should be cancelled");
}

@end
