//
//  LPController.m
//  LaunchpadClean
//
//  Created by Alex Nichol on 9/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LPController.h"

@implementation LPController

- (id)initWithDefaultDatabase {
	NSString * found = nil;
	NSString * library = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
	NSString * appSupport = [library stringByAppendingPathComponent:@"Application Support"];
	NSString * dockSupport = [appSupport stringByAppendingPathComponent:@"Dock"];
	NSArray * listing = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dockSupport error:nil];
	if (listing) {
		for (NSString * str in listing) {
			if ([[str pathExtension] isEqualToString:@"db"]) {
				found = [dockSupport stringByAppendingPathComponent:str];
				break;
			}
		}
	}
	if (!found) {
		[super init]; // might be needed?
		[super dealloc];
		return nil;
	}
	self = [self initWithDatabase:found];
	return self;
}

- (id)initWithDatabase:(NSString *)aPath {
	if ((self = [super init])) {
		database = [[ANSQLite3Manager alloc] initWithDatabaseFile:aPath];
		if (!database) {
			[super dealloc];
			return nil;
		}
	}
	return self;
}

- (NSArray *)readApplications {
	NSMutableArray * resultData = [[NSMutableArray alloc] init];
	NSArray * result = [database executeQuery:@"select * from apps;"];
	for (NSDictionary * row in result) {
		NSString * title = [row objectForKey:@"title"];
		NSString * bundleID = [row objectForKey:@"bundleid"];
		NSString * appPath = pathForApp(bundleID, title);
		if (!appPath) {
			continue;
		}
		
		NSNumber * itemID = [row objectForKey:@"item_id"];
		NSBundle * appBundle = [[NSBundle alloc] initWithPath:appPath];
		
		NSString * iconFilename = [[appBundle infoDictionary] objectForKey:@"CFBundleIconFile"];
		NSString * name = [iconFilename stringByDeletingPathExtension];
		NSString * extension = [iconFilename pathExtension];
		if (!extension || [extension length] == 0) extension = @"icns";
		NSString * iconPath = [appBundle pathForResource:name ofType:extension];
		
		[appBundle release];
		[resultData addObject:[NSDictionary dictionaryWithObjectsAndKeys:title, @"Title",
							   bundleID, @"BundleID", appPath, @"Path", itemID, @"ID", 
							   iconPath, @"Icon", nil]];
	}
	NSArray * immutable = [NSArray arrayWithArray:resultData];
	[resultData release];
	return immutable;
}

- (void)deleteAppWithID:(UInt64)appID {
	NSArray * params = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong:appID], nil];
	[database executeQuery:@"delete from apps where (rowid=?);" withParameters:params];
	[database executeQuery:@"delete from items where (rowid=?);" withParameters:params];
}

- (void)restartDock {
	system("killall Dock");
	// [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:@"/System/Library/CoreServices/Dock.app"]];
	system("open /System/Library/CoreServices/Dock.app");
}

- (void)closeDatabase {
	[database closeDatabase];
	[database release];
	database = nil;
}

- (void)dealloc {
	[self closeDatabase];
	[super dealloc];
}

@end

NSString * pathForApp (NSString * bundleID, NSString * title) {
	NSString * appPath = nil;
	if (!bundleID) {
		NSString * appName = [title stringByAppendingPathExtension:@"app"];
		NSString * testPath = [@"/Applications" stringByAppendingPathComponent:appName];
		if ([[NSFileManager defaultManager] fileExistsAtPath:testPath]) {
			appPath = testPath;
		}
	} else {
		NSArray * listing = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Applications" error:nil];
		for (NSString * anApp in listing) {
			NSString * path = [@"/Applications" stringByAppendingPathComponent:anApp];
			NSBundle * bundle = [[NSBundle alloc] initWithPath:path];
			if (bundle) {
				if ([[bundle bundleIdentifier] isEqualToString:bundleID]) {
					appPath = path;
					break;
				}
				[bundle release];
			}
		}
	}
	return appPath;
}
