//
//  AppDelegate.h
//  StatusMenuAppTest
//
//  Created by Dmitri Shuralyov on 12-03-06.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MAAttachedWindow;
@interface MyWindowController : NSWindowController {}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>

{
    

    NSWindow *window;
    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;

	IBOutlet NSMenuItem * createPublicShareMenuItem;
	IBOutlet NSMenuItem * createPrivateShareMenuItem;
	IBOutlet NSMenuItem * createShoutableShareMenuItem;

    IBOutlet NSMenuItem * settingsMenuItem;

    IBOutlet NSWindow *settingsWindow;
    
    IBOutlet NSTextField * settingsUsername;
    IBOutlet NSTextField * settingsApiKey;
    
    NSString * apiUsername;
    NSString * apiKey;
    
    //IBOutlet NSTextField * settingsUsername;
    //IBOutlet NSTextField * settingsApiKey;
    
    
	MAAttachedWindow *attachedWindow;
    IBOutlet NSView *view;
    IBOutlet NSTextField *textField;

	NSPoint notificationPosition;

	char sourceImageDataType;		// 0 == nil, 1 == PNG, 2 == TIFF
	NSData * sourceImageData;
	bool targetImageDataExistsPng;
	NSData * targetImageDataPng;
	bool targetImageDataExistsJpg;
	NSData * targetImageDataJpg;
    
    NSData * targetImageDataTxt;
    bool targetImageDataExistsTxt;


	
	NSThread * conversionPngThread;
	NSThread * conversionJpgThread;
	
	char requestedUploadAction;		// 0 == nil, 1 == PNG, 2 == JPG

	NSTimer * closeTimer;
	NSTimer * repeatingTimer;
}

- (void)toggleAttachedWindowAtPoint:(NSPoint)pt message:(NSString *)message withUrl:(NSURL *)Url;

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, strong) MyWindowController *windowController;

@property (strong) IBOutlet NSTextField * settingsUsername;

@property (strong) IBOutlet NSTextField * settingsApiKey;

@end

@interface ItemAndTitle : NSObject
{
@public
	NSMenuItem * item;
	NSString * title;
}
@end





