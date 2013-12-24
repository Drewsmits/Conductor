//
//  CDCoreDataOperation.m
//  Conductor
//
//  Created by Andrew Smith on 6/17/12.
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


#import "CDCoreDataOperation.h"

@interface CDCoreDataOperation ()
@property (nonatomic, strong, readwrite) NSManagedObjectContext *backgroundContext;
- (NSManagedObjectContext *)newThreadSafeManagedObjectContext;
@end

@implementation CDCoreDataOperation

+ (CDCoreDataOperation *)operationWithMainContext:(NSManagedObjectContext *)mainContext 
{
    CDCoreDataOperation *operation = [self new];
    operation.mainContext = mainContext;
    return operation;
}

- (void)main
{    
    @autoreleasepool {
        if (self.isCancelled) {
            [self finish];
            return;
        }
        
        //
        // Spin up a new thread safe context here for thread confinement
        //
        self.backgroundContext = [self newThreadSafeManagedObjectContext];
        
        //
        // Do your work
        //
        [self work];
        
        //
        // Cleanup
        //
        [self finish];
    }
}

#pragma mark - Contexts

- (BOOL)saveBackgroundContext
{
    __block BOOL saved = NO;
    if (self.backgroundContext.hasChanges) {
        [self.backgroundContext performBlockAndWait:^{
            NSError *error;
            saved = [self.backgroundContext save:&error];
            if (!saved) {
                ConductorLog(@"Save failed: %@", error);
            };
        }];
    }
    return saved;
}

- (void)queueMainContextSave
{
    [self.mainContext performBlock:^{
        NSError *error;
        if (![self.mainContext save:&error]) {
            ConductorLog(@"Save failed: %@", error);
        }
    }];
}

- (NSManagedObjectContext *)newThreadSafeManagedObjectContext
{
    if (!self.mainContext) return nil;
   
    //
    // Build private queue context as child of main context
    //
    NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [newContext setParentContext:self.mainContext];
    
    //
    // Optimization
    //
    [newContext setUndoManager:nil];

    return newContext;
}

@end
