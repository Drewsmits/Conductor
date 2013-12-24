//
//  CDQueueController+Test.m
//  Conductor
//
//  Created by Andrew Smith on 3/21/13.
//  Copyright (c) 2013 Andrew B. Smith ( http://github.com/drewsmits ). All rights reserved.
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


#import "CDQueueController+Test.h"

@implementation CDQueueController (Test)

- (void)waitForQueueNamed:(NSString *)queueName
{
    /**
     This is really only meant for testing async code.  This blocks the current thread and dissalows
     adding more opperations to the queue from this thread. Given that tests all run on the main loop,
     it is pretty easy to accidentally deadlock your test accidentally, so be careful.
     */
    
    CDOperationQueue *queue = [self getQueueNamed:queueName];
    
    if (!queue.isExecuting) return;
    
    //
    // Wait until Apple thinks all operations are finished
    //
    [queue.queue waitUntilAllOperationsAreFinished];
}

- (void)logAllOperations
{
    NSArray *queueNames = [self allQueueNames];    
    for (NSString *queueName in queueNames) {
        [self logAllOperationsInQueueNamed:queueName];
    }
}

- (void)logAllOperationsInQueueNamed:(NSString *)queueName
{
    CDOperationQueue *queue = [self getQueueNamed:queueName];
    NSLog(@"Operations in %@: %@", queueName, queue.operations);
}

@end
