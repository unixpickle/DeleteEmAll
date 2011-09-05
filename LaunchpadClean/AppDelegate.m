//
//  LaunchpadCleanAppDelegate.m
//  LaunchpadClean
//
//  Created by Alex Nichol on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (Private)

- (void)bgApplyThread:(NSArray *)deleteMe;
- (void)loadingDone;

@end

@implementation AppDelegate

@synthesize window;
@synthesize applications;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
	if (isInBackground) return;
	self.applications = [launchpad readApplications];
	[tableView reloadData];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

- (void)awakeFromNib {
	checkedApps = [[NSMutableDictionary alloc] init];
	launchpad = [[LPController alloc] initWithDefaultDatabase];
	self.applications = [launchpad readApplications];
	for (NSDictionary * app in self.applications) {
		[checkedApps setObject:[NSNumber numberWithBool:YES] forKey:[app objectForKey:@"ID"]];
	}
	
	NSRect tableFrame = [tableContainer bounds];
	tableView = [[NSTableView alloc] initWithFrame:tableFrame];
	// create columns for our table
	NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"Checked"];
	NSTableColumn * column2 = [[NSTableColumn alloc] initWithIdentifier:@"Icon"];
	NSTableColumn * column3 = [[NSTableColumn alloc] initWithIdentifier:@"Name"];
	NSTableColumn * column4 = [[NSTableColumn alloc] initWithIdentifier:@"Path"];
	
	[column1 setWidth:16];
	[column2 setWidth:16];
	[column3 setWidth:(tableFrame.size.width - 52) / 2];
	[column4 setWidth:(tableFrame.size.width - 52) / 2];
	[[column1 headerCell] setImage:[NSImage imageNamed:@"check.png"]];
	[[column2 headerCell] setImage:[NSImage imageNamed:@"app.png"]];
	[[column3 headerCell] setTitle:@"Name"];
	[[column4 headerCell] setTitle:@"Path"];
		
	[tableView addTableColumn:column1];
	[tableView addTableColumn:column2];
	[tableView addTableColumn:column3];
	[tableView addTableColumn:column4];
	[tableView setDelegate:self];
	[tableView setDataSource:self];
	[tableView reloadData];
	[tableView setAutoresizingMask:0x7f];
	[tableContainer setAutoresizesSubviews:YES];
	
	// embed the table view in the scroll view, and add the scroll view
	// to our window.
	[tableContainer setDocumentView:tableView];
	[tableContainer setHasVerticalScroller:YES];
	[[window contentView] addSubview:tableContainer];
		
	[column1 release];
	[column2 release];
	[column3 release];
	[column4 release];
}

#pragma mark Table View

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self.applications count];;
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (!tableColumn) return nil;
	if ([[tableColumn identifier] isEqualToString:@"Checked"]) {
		NSButtonCell * cell = [[NSButtonCell alloc] init];
		[cell setAllowsMixedState:YES];
		[cell setButtonType:NSSwitchButton];
		[cell setAllowsMixedState:NO];
		return [cell autorelease];
	} else if ([[tableColumn identifier] isEqualToString:@"Icon"]) {
		NSImageCell * img = [[NSImageCell alloc] initImageCell:[NSImage imageNamed:@"app.png"]];
		return [img autorelease];
	}
	return nil;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSDictionary * app = [self.applications objectAtIndex:row];
	if ([[tableColumn identifier] isEqualToString:@"Checked"]) {
		NSNumber * n = [checkedApps objectForKey:[app objectForKey:@"ID"]];
		if (n) return n;
		return [NSNumber numberWithBool:NO];
	} else if ([[tableColumn identifier] isEqualToString:@"Icon"]) {
		NSImage * image = [[NSImage alloc] initWithContentsOfFile:[app objectForKey:@"Icon"]];
		if (!image) {
			NSLog(@"No image");
		}
		return [image autorelease];
	} else if ([[tableColumn identifier] isEqualToString:@"Name"]) {
		[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:17]];
		return [app objectForKey:@"Title"];
	} else {
		return [app objectForKey:@"Path"];
	}
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
	return 24;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"Checked"]) {
		NSNumber * appID = [[self.applications objectAtIndex:row] objectForKey:@"ID"];
		[checkedApps setObject:object forKey:appID];
	}
}

#pragma mark UI

- (IBAction)applyChanges:(id)sender {
	[indicator startAnimation:self];
	[applyButton setEnabled:NO];
	[tableView setEnabled:NO];
	NSMutableArray * deleteMe = [NSMutableArray array];
	for (NSDictionary * app in self.applications) {
		NSNumber * appID = [[[app objectForKey:@"ID"] copy] autorelease];
		NSNumber * n = [checkedApps objectForKey:[app objectForKey:@"ID"]];
		if (!n || ![n boolValue]) {
			[deleteMe addObject:appID];
		}
	}
	isInBackground = YES;
	[self performSelectorInBackground:@selector(bgApplyThread:) withObject:deleteMe];
}

- (void)bgApplyThread:(NSArray *)deleteMe {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[NSThread sleepForTimeInterval:1];
	for (NSNumber * n in deleteMe) {
		[launchpad deleteAppWithID:(UInt64)[n unsignedLongLongValue]];
	}
	[launchpad restartDock];
	[self performSelectorOnMainThread:@selector(loadingDone) 
						   withObject:nil waitUntilDone:NO];
	[pool drain];
}

- (void)loadingDone {
	isInBackground = NO;
	[indicator stopAnimation:self];
	[applyButton setEnabled:YES];
	[tableView setEnabled:YES];
	[self applicationDidBecomeActive:nil];
}

#pragma mark Memory Management

- (void)dealloc {
	self.applications = nil;
	[checkedApps release];
	[tableView release];
	[super dealloc];
}

@end
