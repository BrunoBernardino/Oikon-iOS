//
//  AppDelegate.m
//  Oikon
//
//  Created by Bruno Bernardino on 23/05/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    //self.window.backgroundColor = [UIColor whiteColor];
    //[self.window makeKeyAndVisible];
    
    // We need to override the main storyboard so it uses localization
    NSString *storyboardName = @"Main";
    NSString *language = @"Base";
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *preferred = [[mainBundle preferredLocalizations] objectAtIndex:0];
    if ( [[mainBundle localizations] containsObject:preferred] ) {
        language = preferred;
    }
    
    NSBundle *bundle = [NSBundle bundleWithPath:[mainBundle pathForResource:language ofType:@"lproj"]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:bundle];
	
	// Make the status bar white
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
	
	// Synchronize settings
	[ self synchronizeSettings ];
	
	// Set passcode requirement
	[self setPasscodeRequirementIfNecessary];
    
    // Start with new view controller
    self.window.rootViewController = [storyboard instantiateInitialViewController];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	
	// Set blank splash screen (this is not working)
	self.splashView = [[UIImageView alloc] initWithFrame:self.window.frame];
	[self.splashView setImage:[UIImage imageNamed:@"splash(640x1136).png"]];// TODO: Find a better way for this to fit on iPhone 4/4S
	self.splashView.bounds = CGRectMake(0, 0, self.window.bounds.size.width, self.window.bounds.size.height);
	[self.window addSubview:self.splashView];
	
	// Set passcode requirement
	[self setPasscodeRequirementIfNecessary];
	
	// This delay is necessary to have the splash be added on time
	[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	
	// Synchronize settings
	[ self synchronizeSettings ];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	if ( self.splashView != nil ) {
        [self.splashView removeFromSuperview];
        self.splashView = nil;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
	
	// Set passcode requirement
	[self setPasscodeRequirementIfNecessary];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Oikon" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [self currentStoreURL];
	
	//self.managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;// This crashes the app
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if ( ! [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:self.storeOptions error:&error] ) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
		[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		self.storeOptions = @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES};
		[_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:self.storeOptions error:&error];
		
        NSLog(@"Unresolved error while initializing %@, %@", error, [error userInfo]);
        //abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

// Get current store URL (it will change based on if iCloud is enabled or not)
- (NSURL *) currentStoreURL
{
	return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Oikon.sqlite"];
}

// Store options for iCloud
- (NSDictionary *) iCloudStoreOptions
{
	return @{ NSPersistentStoreUbiquitousContentNameKey: @"iCloudStore" };
}

// Store options for local
- (NSDictionary *) localStoreOptions
{
	return nil;
}

// Reload store
- (void) reloadWithNewStore:(NSPersistentStore *)newStore
{
	NSLog(@"RELOADING STORE");

	if ( newStore ) {
		NSError *error = nil;
        if ( ! [_persistentStoreCoordinator removePersistentStore:newStore error:&error] ) {
			NSLog(@"Unresolved error while removing persistent store %@, %@", error, [error userInfo]);
		}
		
    }
	
    [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self currentStoreURL] options:self.storeOptions error:nil];
}

// Set / Get default settings
- (void) synchronizeSettings
{
	NSLog( @"## Starting settings synchronization ##" );
	self.settings = [NSUserDefaults standardUserDefaults];
	[self.settings synchronize];
	
	// Passcode
	if ( [self.settings valueForKey:@"passcode"] == nil ) {
		[self.settings setValue:nil forKey:@"passcode"];
	}
	
	// iCloud sync
	if ( [[NSUserDefaults standardUserDefaults] objectForKey:@"iCloud"] == nil ) {
		NSMutableDictionary *defaultiCloud = [[NSMutableDictionary alloc] initWithCapacity:5];
		
		[defaultiCloud setValue:@NO forKey:@"isEnabled"];
		[defaultiCloud setValue:nil forKey:@"lastSyncStart"];// Last time a sync was started from the app
		[defaultiCloud setValue:nil forKey:@"lastSuccessfulSync"];// Last time a sync was finished successfully from the app
		[defaultiCloud setValue:nil forKey:@"lastRemoteSync"];// Last time an update existed remotely
		[defaultiCloud setValue:nil forKey:@"lastLocalUpdate"];// Last time something was updated locally
		
		[self.settings setObject:defaultiCloud forKey:@"iCloud"];
	} else {
		NSMutableDictionary *iCloudSettings = [[NSMutableDictionary alloc] initWithCapacity:5];
		
		iCloudSettings = [self.settings objectForKey:@"iCloud"];
		
		if ( [iCloudSettings valueForKey:@"isEnabled"] ) {
			self.storeOptions = [self iCloudStoreOptions];
		} else {
			self.storeOptions = [self localStoreOptions];
		}
	}
    
    // Search dates
	if ( [self.settings valueForKey:@"searchFromDate"] == nil ) {
		[self.settings setValue:nil forKey:@"searchFromDate"];
	}
    
    if ( [self.settings valueForKey:@"searchToDate"] == nil ) {
		[self.settings setValue:nil forKey:@"searchToDate"];
	}
    
    // Filters - Type
    if ( [self.settings valueForKey:@"filterTypes"] == nil ) {
		[self.settings setValue:nil forKey:@"filterTypes"];
	}
    
    // Filters - Name
    if ( [self.settings valueForKey:@"filterName"] == nil ) {
		[self.settings setValue:nil forKey:@"filterName"];
	}
	
	[self.settings synchronize];
}

// Set passcode requirement if necessary (if it's in the settings)
- (void) setPasscodeRequirementIfNecessary
{
	NSLog( @"## Setting passcode requirement if necessary ##" );

	if ( [self.settings valueForKey:@"passcode"] != nil ) {
		self.willAskForPasscode = YES;
	} else {
		self.willAskForPasscode = NO;
	}
}

// Does the passcode need to be asked for?
- (BOOL) needsToShowPasscode
{
	NSLog( @"## Asking if passcode is necessary to show: %@ ##", self.willAskForPasscode ? @"YES":@"NO" );
	return self.willAskForPasscode;
}

// Is the passcode valid? (string comparison)
- (BOOL )isPasscodeValid:(NSString *)passcode
{
	// Convert passcode to number
	NSNumber *passcodeTried = [NSNumber numberWithInt:[passcode intValue]];

	if ( [passcodeTried isEqualToNumber:[self.settings valueForKey:@"passcode"]] ) {
		return YES;
	} else {
		return NO;
	}
}

// Is the passcode valid? (number comparison)
- (BOOL) isPasscodeValidWithNumber:(NSNumber *)passcode
{
	if ( [passcode isEqualToNumber:[self.settings valueForKey:@"passcode"]] ) {
		return YES;
	} else {
		return NO;
	}
}

// Update iCloud start sync date
- (void) setiCloudStartSyncDate
{
	// Sync data if this is being called too son
	if ( self.settings == nil ) {
		[self synchronizeSettings];
	}

	NSMutableDictionary *iCloudSettings = [[self.settings objectForKey:@"iCloud"] mutableCopy];
	
	NSLog(@"Set the sync start date to now");
	
	// Set the sync start date to now
	[iCloudSettings setValue:[NSDate date] forKey:@"lastSyncStart"];
	
	[self.settings setObject:iCloudSettings forKey:@"iCloud"];
}

// Update iCloud end sync date
- (void) setiCloudEndSyncDate
{
	// Sync data if this is being called too son
	if ( self.settings == nil ) {
		[self synchronizeSettings];
	}

	NSMutableDictionary *iCloudSettings = [[self.settings objectForKey:@"iCloud"] mutableCopy];
	
	NSLog(@"Set the sync end date to now");

	// Set the sync end date to now
	[iCloudSettings setValue:[NSDate date] forKey:@"lastSuccessfulSync"];
	
	[self.settings setObject:iCloudSettings forKey:@"iCloud"];
}

// Migrate data to iCloud
- (void) migrateDataToiCloud
{
	NSLog(@"Migrating data to iCloud");
		
	NSMutableDictionary *tmpStoreOptions = [self.storeOptions mutableCopy];
		
	[tmpStoreOptions setObject:@YES forKey:NSPersistentStoreRemoveUbiquitousMetadataOption];

	//NSPersistentStore *store = [_persistentStoreCoordinator persistentStoreForURL:[self currentStoreURL]];
	
	NSPersistentStore *tmpStore = nil;//[_persistentStoreCoordinator migratePersistentStore:store toURL:[self currentStoreURL] options:tmpStoreOptions withType:NSSQLiteStoreType error:nil];
	
	// Update store options for reload
	self.storeOptions = [self iCloudStoreOptions];
	
	// Reload store
	[self reloadWithNewStore: tmpStore];
	
	NSMutableDictionary *iCloudSettings = [[self.settings objectForKey:@"iCloud"] mutableCopy];
	
	NSLog(@"Set the last remote sync date to now");
	
	// Set the last remote sync date to now
	[iCloudSettings setValue:[NSDate date] forKey:@"lastRemoteSync"];
	
	[self.settings setObject:iCloudSettings forKey:@"iCloud"];
}

// Migrate data to Local
- (void) migrateDataToLocal
{
	NSLog(@"Migrating data to Local");

	NSMutableDictionary *tmpStoreOptions = [self.storeOptions mutableCopy];
	
	[tmpStoreOptions setObject:@YES forKey:NSPersistentStoreRemoveUbiquitousMetadataOption];
	
	//NSPersistentStore *store = [_persistentStoreCoordinator persistentStoreForURL:[self currentStoreURL]];
	
	NSPersistentStore *tmpStore = nil;//[_persistentStoreCoordinator migratePersistentStore:store toURL:[self currentStoreURL] options:tmpStoreOptions withType:NSSQLiteStoreType error:nil];
	
	// Update store options for reload
	self.storeOptions = [self localStoreOptions];
	
	// Reload store
	[self reloadWithNewStore: tmpStore];
	
	NSMutableDictionary *iCloudSettings = [[self.settings objectForKey:@"iCloud"] mutableCopy];
	
	NSLog(@"Set the last local sync date to now");
	
	// Set the last local sync date to now
	[iCloudSettings setValue:[NSDate date] forKey:@"lastLocalUpdate"];
	
	[self.settings setObject:iCloudSettings forKey:@"iCloud"];
}

// Remove all data
- (void) removeAllData
{
	NSLog(@"REMOVING ALL DATA!");

	// HINT?: Use @{ NSPersistentStoreRebuildFromUbiquitousContentOption: @YES } if iCloud is enabled
	NSPersistentStore *store = [_persistentStoreCoordinator persistentStoreForURL:[self currentStoreURL]];

	[self.persistentStoreCoordinator removePersistentStore:store error:nil];
	[[NSFileManager defaultManager] removeItemAtURL:[store URL] error:nil];

	_managedObjectContext = nil;
	_persistentStoreCoordinator = nil;
	
	// Reload data
	[self managedObjectContext];
	[self persistentStoreCoordinator];
}

@end
