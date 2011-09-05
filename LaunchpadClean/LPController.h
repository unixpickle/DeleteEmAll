//
//  LPController.h
//  LaunchpadClean
//
//  Created by Alex Nichol on 9/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANSQLite3Manager.h"

/**
 * An interface for modifying the Launchpad configuration database.
 */
@interface LPController : NSObject {
	ANSQLite3Manager * database;
}

/**
 * Create a new Launchpad controller with the default Dock database
 * stored in Application Support.
 */
- (id)initWithDefaultDatabase;

/**
 * Create a new Launchpad controller with a custom SQLite3 database
 * file.
 */
- (id)initWithDatabase:(NSString *)aPath;

/**
 * Returns an array of NSDictionary objects.  Each dictionary contains
 * several keys, such as @"Title", @"Path", and @"ID".
 */
- (NSArray *)readApplications;

/**
 * Remove an application from the launchpad database.
 * @param appID The ROWID of the item to delete.  This should be a valid
 * @"ID" key from -readApplications.
 */
- (void)deleteAppWithID:(UInt64)appID;

/**
 * Kills the dock process, then re-launches it.  This method
 * may block for a few seconds, and should be run on a
 * background thread as to not block the UI.
 */
- (void)restartDock;

/**
 * Closes the SQLite connection.  This will be called automatically by
 * dealloc if it wasn't already.
 */
- (void)closeDatabase;

@end

NSString * pathForApp (NSString * bundleID, NSString * title);
