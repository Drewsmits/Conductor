//
//  CDCoreDataOperation.m
//  Conductor
//
//  Created by Andrew Smith on 6/25/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//


#import "CDCoreDataOperationTests.h"
#import "Conductor.h"

#import "CDCoreDataOperation.h"
#import "CDTestCoreDataOperation.h"
#import "ConductorTestMacros.h"

@implementation CDCoreDataOperationTests

- (void)setUp
{
    [super setUp];
    
    DeleteDataStore();
    
    // Build Model
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:DataModelURL()];
    
    STAssertNotNil(model, @"Managed Object Model should exist");
    
    // Build persistent store coordinator
    coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    // Build Store
    NSError *error = nil;
    store = [coord addPersistentStoreWithType:NSSQLiteStoreType
                                configuration:nil
                                          URL:DataStoreURL()
                                      options:nil 
                                        error:&error];
    
    // Build context
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [context setPersistentStoreCoordinator:coord];
}

- (void)tearDown
{
    NSError *error = nil;
    STAssertTrue([coord removePersistentStore:store error:&error], 
                 @"couldn't remove persistent store: %@", error);
        
    [super tearDown];
}

- (void)testStart
{
    CDCoreDataOperation *operation = [CDCoreDataOperation operationWithMainContext:context];
    
    [operation start];
    
    STAssertNotNil(operation.backgroundContext, @"Operation background context should not be nil!");
}

- (void)testBackgroundContextDidSave
{    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Employee" inManagedObjectContext:context];
    [request setEntity:entity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"1 = 1"]];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    
    STAssertEquals([results count], 0U, @"Should only have one employee");

    __block BOOL hasFinished = NO;
    void (^completionBlock)(void) = ^(void) {
        hasFinished = YES;
    };
    
    
    CDTestCoreDataOperation *operation = (CDTestCoreDataOperation *)[CDTestCoreDataOperation operationWithMainContext:context];
    operation.completionBlock = completionBlock;
    
    [conductor addOperation:operation toQueueNamed:CONDUCTOR_TEST_QUEUE];
        
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    [conductor waitForQueueNamed:CONDUCTOR_TEST_QUEUE];
    
    results = [context executeFetchRequest:request error:&error];
    
    NSManagedObject *employee = [results lastObject];

    STAssertEquals([results count], 1U, @"Should only have one employee");
    STAssertEqualObjects([employee valueForKey:@"employeeID"], @1, @"Employee should have correct ID");
}

@end
