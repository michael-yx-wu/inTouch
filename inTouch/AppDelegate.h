//
//  AppDelegate.h
//  inTouch
//
//  Created by Naicheng Wangyu 03/03/14
//  Copyright (c) 2014 Naicheng Wangyu. All rights reserved.
//

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;


- (void)updateContacts;
- (void)updateContactsUrgency;
- (void)saveContext;

@end
