//
//  AppDelegate.h
//  Oikon
//
//  Created by Bruno Bernardino on 23/05/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIImageView *splashView;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NSUserDefaults *settings;
@property (nonatomic, assign) BOOL willAskForPasscode;

@property (strong, nonatomic) NSDictionary *storeOptions;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void) saveContext;
- (NSURL *) applicationDocumentsDirectory;
- (void) synchronizeSettings;
- (BOOL) needsToShowPasscode;
- (void) setPasscodeRequirementIfNecessary;
- (BOOL) isPasscodeValid:(NSString *)passcode;
- (BOOL) isPasscodeValidWithNumber:(NSNumber *)passcode;

- (void) setiCloudStartSyncDate;
- (void) setiCloudEndSyncDate;
- (void) migrateDataToiCloud;
- (void) migrateDataToLocal;

- (void) removeAllData;

@end
