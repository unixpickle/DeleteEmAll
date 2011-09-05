//
//  LaunchpadCleanAppDelegate.h
//  LaunchpadClean
//
//  Created by Alex Nichol on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LPController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate> {
	NSWindow * window;
	NSTableView * tableView;
	IBOutlet NSScrollView * tableContainer;
	IBOutlet NSProgressIndicator * indicator;
	IBOutlet NSButton * applyButton;
	
	BOOL isInBackground;
	LPController * launchpad;
	NSArray * applications;
	NSMutableDictionary * checkedApps;
}

@property (assign) IBOutlet NSWindow * window;
@property (nonatomic, retain) NSArray * applications;

- (IBAction)applyChanges:(id)sender;

@end
