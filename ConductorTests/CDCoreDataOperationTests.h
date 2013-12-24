//
//  CDCoreDataOperation.h
//  Conductor
//
//  Created by Andrew Smith on 6/25/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "CDTest.h"

@interface CDCoreDataOperationTests : CDTest {
    NSPersistentStoreCoordinator *coord;
    NSManagedObjectContext *context;
    NSManagedObjectModel *model;
    NSPersistentStore *store;
}

@end
