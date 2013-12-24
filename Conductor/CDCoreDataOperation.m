//
//  CDCoreDataOperation.m
//  Conductor
//
//  Created by Andrew Smith on 6/17/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
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
