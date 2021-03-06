//
//  AppDelegate.m
//  StatusMenuAppTest
//
//  Created by Dmitri Shuralyov on 12-03-06.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "MAAttachedWindow.h"

#define DECISION_KEEP_NOTIFICATIONS_IN_NC 1

@implementation ItemAndTitle
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize settingsUsername = _settingsUsername;
@synthesize settingsApiKey = _se;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
	// Set self as NSUserNotificationCenter delegate
    
    
    // Get defaults out of NSUserDefaults
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    apiUsername    = [defaults stringForKey:@"apiUsername"];
    if (apiUsername == nil) apiUsername = @"mericson";
    
    apiKey    = [defaults stringForKey:@"apiKey"];
    if (apiKey == nil) apiKey = @"enter your api key here";
        
    apiUrl    = [defaults stringForKey:@"apiUrl"];
    if (apiUrl == nil) apiUrl = @"http://localhost:4567";
    
    
    
    NSLog( apiUrl );
    
    attachedWindow = nil;
	closeTimer = nil;
	repeatingTimer = nil;
    
	sourceImageDataType = 0;
	sourceImageData = nil;
	targetImageDataExistsPng = false;
	targetImageDataPng = nil;
	targetImageDataExistsJpg = false;
	targetImageDataJpg = nil;
    
    targetImageDataTxt = nil;
    targetImageDataExistsTxt = false;
    
	conversionPngThread = nil;
	conversionJpgThread = nil;
    
	requestedUploadAction = 0;
    
    if ( ! statusItem ) {
        NSLog( @"Creating Menu" );
        statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        //[statusItem setTitle:@"Status"];
        NSSize app_icon_size = NSMakeSize(16, 16);
        NSImage * app_icon = [NSImage imageNamed:@"Icon"];
        [app_icon setSize: app_icon_size];
        NSImage * app_icon_inv = [NSImage imageNamed:@"Icon-inv"];
        [app_icon_inv setSize: app_icon_size];
        [statusItem setImage:app_icon];
        [statusItem setAlternateImage: app_icon_inv];
        [statusItem setHighlightMode:YES];
        
        [statusItem setMenu:statusMenu];
        /*[statusItem setAction:@selector(openMenu:)];
         [statusItem sendActionOn: NSLeftMouseDownMask];
         [statusItem setTarget:self];*/
        
        [statusItem setToolTip:@"Instant Background Uploader (0.007)"];
    }

    
    
	[[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate: self];

	// If we were opened from a user notification, do the corresponding action
	{
		NSUserNotification * launchNotification = [[aNotification userInfo] objectForKey: NSApplicationLaunchUserNotificationKey];
		if (launchNotification)
			[self userNotificationCenter: nil didActivateNotification: launchNotification];
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
#if DECISION_KEEP_NOTIFICATIONS_IN_NC
	// Clear all notifications
	[[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
#endif
}

- (IBAction)CreatePrivateShare:(id)sender
{
	//while (!(nil != conversionPngThread && [conversionPngThread isFinished]))
	while (!targetImageDataExistsPng)
		usleep(50);

	requestedUploadAction = 1;
	[self UploadImage];
}

- (IBAction)CreatePublicShare:(id)sender
{
	//while (!(nil != conversionJpgThread && [conversionJpgThread isFinished]))
	while (!targetImageDataExistsPng)
		usleep(50);

	requestedUploadAction = 2;
	[self UploadImage];
}

- (IBAction)CreateShoutableShare:(id)sender
{
	//while (!(nil != conversionJpgThread && [conversionJpgThread isFinished]))
	while (!targetImageDataExistsPng)
		usleep(50);
    
	requestedUploadAction = 3;
	[self UploadImage];
}

- (IBAction)ShowSettingsBox:(id)sender
{
    
    if (self.windowController == nil) {
        self.windowController = [[MyWindowController alloc]
                                 initWithWindowNibName:@"SettingsWindow"];
    }

    
    /*NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ( apiUsername = [prefs stringForKey:@"apiUsername"] ) {
    } else {
        apiUsername = @"monkeys";
    }
    
    if ( apiKey = [prefs stringForKey:@"apiKey"] ) {
    } else {
        apiKey = @"dogs";
    }
   
    [self.windowController setUsernameAndApiKey:apiUsername apiKey:apiKey]; */
    
    [self.windowController showWindow:nil];
    [self.windowController setAppDelegate:self];
    
    NSLog( apiUsername );



//
    
    //MyWindowController* controller = [[MyWindowController alloc] init];
    //[controller showWindow:self];
    
}

- (void)SaveSettings:(NSString*)username apiKey:(NSString *)key
{
    NSLog(@"Saving settings from App Delegate!");
}

-(NSString *)Base64Encode:(NSData *)data{
	// Point to start of the data and set buffer sizes
	unsigned long inLength = [data length];
	unsigned long outLength = ((((inLength * 4)/3)/4)*4) + (((inLength * 4)/3)%4 ? 4 : 0);
	const char *inputBuffer = [data bytes];
	char *outputBuffer = malloc(outLength);
	outputBuffer[outLength] = 0;

	// 64 digit code
	static char Encode[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	// start the count
	unsigned long cycle = 0;
	unsigned long inpos = 0;
	unsigned long outpos = 0;
	char temp;

	// Pad the last to bytes, the outbuffer must always be a multiple of 4
	outputBuffer[outLength-1] = '=';
	outputBuffer[outLength-2] = '=';

	/* http://en.wikipedia.org/wiki/Base64
	 Text content   M           a           n
	 ASCII          77          97          110
	 8 Bit pattern  01001101    01100001    01101110

	 6 Bit pattern  010011  010110  000101  101110
	 Index          19      22      5       46
	 Base64-encoded T       W       F       u
	 */

	while (inpos < inLength){
		switch (cycle) {
			case 0:
				outputBuffer[outpos++] = Encode[(inputBuffer[inpos]&0xFC)>>2];
				cycle = 1;
				break;
			case 1:
				temp = (inputBuffer[inpos++]&0x03)<<4;
				outputBuffer[outpos] = Encode[temp];
				cycle = 2;
				break;
			case 2:
				outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xF0)>> 4];
				temp = (inputBuffer[inpos++]&0x0F)<<2;
				outputBuffer[outpos] = Encode[temp];
				cycle = 3;
				break;
			case 3:
				outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xC0)>>6];
				cycle = 4;
				break;
			case 4:
				outputBuffer[outpos++] = Encode[inputBuffer[inpos++]&0x3f];
				cycle = 0;
				break;
			default:
				cycle = 0;
				break;
		}
	}
	NSString *pictemp = [NSString stringWithUTF8String:outputBuffer];
	free(outputBuffer);
	return pictemp;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
#if DECISION_KEEP_NOTIFICATIONS_IN_NC
	NSString * imageUrl;
	if (   nil != [notification userInfo]
		&& nil != (imageUrl = [[notification userInfo] objectForKey: @"ImageUrl"])
		&& [imageUrl length] > 0)
	{}
	else
	{
		[center removeDeliveredNotification: notification];
	}
#else
	[center removeDeliveredNotification: notification];
#endif
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
	return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
#if DECISION_KEEP_NOTIFICATIONS_IN_NC
	[center removeDeliveredNotification: notification];
#endif

	//NSLog(@"%ld", [notification activationType]);
	//NSLog(@"%@", notification);

	NSString * imageUrl;
	if (   nil != [notification userInfo]
		&& nil != (imageUrl = [[notification userInfo] objectForKey: @"ImageUrl"])
		&& [imageUrl length] > 0)
	{
		// Set clipboard contents to a string
		[self setPasteboardString: imageUrl];

		// Open it in a browser
		[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: imageUrl]];
	}
	else
	{}
}

// Set clipboard contents to a string
- (void)setPasteboardString:(NSString *)string
{
	NSPasteboard * pb = [NSPasteboard generalPasteboard];
	NSArray * types = [NSArray arrayWithObjects:NSStringPboardType, nil];
	[pb declareTypes:types owner:self];
	[pb setString:string forType:NSStringPboardType];
}

- (IBAction)UploadImageAsNotificationCenter:(id)sender
{
	NSString * imageUrl = @"http://img209.imageshack.us/img209/8207/imageel.png";
	//NSString * imageUrl = @"";
	NSString * failReason;

	[self displayUserNotification: imageUrl failReason: failReason];
}

- (IBAction)UploadImage
{
	NSData * data = nil;
    NSString *shareType = @"private";
    
    /* Update username out of settings */
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    apiUsername    = [defaults stringForKey:@"apiUsername"];
    if (apiUsername == nil) apiUsername = @"mericson";
    
    apiKey    = [defaults stringForKey:@"apiKey"];
    if (apiKey == nil) apiKey = @"enter your api key here";
    
    apiUrl    = [defaults stringForKey:@"apiUrl"];
    if (apiUrl == nil) apiUrl = @"http://localhost:4567/receive";
    
    /* Figure out type of share */

	if (0 == requestedUploadAction)
	{
		return;
	}
	else if (1 == requestedUploadAction && targetImageDataExistsPng)
	{
		data = targetImageDataPng;
	}
	else if (2 == requestedUploadAction && targetImageDataExistsPng)
	{
		data = targetImageDataPng;
        shareType = @"public";
	}
    else if (3 == requestedUploadAction && targetImageDataExistsPng)
	{
		data = targetImageDataPng;
        shareType = @"shoutable";
	}
	else
	{
		NSLog(@"Error, something went wrong in UploadImage\n");
		return;
	}

	if (nil != data)
	{
		// Upload image
		NSString *urlString = @"http://localhost:4567/receive";
		NSString *filename;
		NSString *type;
        filename = @"Image.png";
        type = @"image/png";
		NSString * key = @"12DEFKTYa5517607af7de06ec6272205d57a9cf4";
		NSMutableURLRequest * request= [[NSMutableURLRequest alloc] init];
		[request setURL:[NSURL URLWithString:urlString]];
		[request setHTTPMethod:@"POST"];
		NSString *boundary = @"---------------------------14737809831466499882746641449";
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
		[request addValue:contentType forHTTPHeaderField: @"Content-Type"];
		NSMutableData *postbody = [NSMutableData data];
		
        /*[postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"key\"\r\n\r\n%@\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        */
        
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"username\"\r\n\r\n%@\r\n", apiUsername] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"api_key\"\r\n\r\n%@\r\n", apiKey] dataUsingEncoding:NSUTF8StringEncoding]];
      
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"share_type\"\r\n\r\n%@\r\n", shareType] dataUsingEncoding:NSUTF8StringEncoding]];
        
        if ( sourceImageDataType == 1 || sourceImageDataType == 2 ) {
        
            [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"share_format\"\r\n\r\n%@\r\n", @"image"] dataUsingEncoding:NSUTF8StringEncoding]];
            
            [postbody appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file_upload\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
            
            [postbody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", type] dataUsingEncoding:NSUTF8StringEncoding]];
            [postbody appendData:[NSData dataWithData:data]];
        }  else if ( sourceImageDataType == 3 ) {
            
            [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"share_format\"\r\n\r\n%@\r\n", @"text"] dataUsingEncoding:NSUTF8StringEncoding]];
            
            NSString * dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"text_upload\"\r\n\r\n%@\r\n", dataStr] dataUsingEncoding:NSUTF8StringEncoding]];
            
        }
        

        
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
		[request setHTTPBody:postbody];
		
		NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
		NSString * returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
		//NSLog(@"%@\n", returnString);

		// Try to parse the <image_link> out of the response
		NSString * imageUrl = @"";
		do
		{
			NSRange StartRange = [returnString rangeOfString:@"<share_link>" options:NSCaseInsensitiveSearch];
			if (StartRange.location == NSNotFound) break;
			NSRange EndRange = [returnString rangeOfString:@"</share_link>" options:NSCaseInsensitiveSearch range:NSMakeRange(StartRange.location + StartRange.length, [returnString length] - (StartRange.location + StartRange.length))];
			if (EndRange.location == NSNotFound) break;
			imageUrl = [returnString substringWithRange:NSMakeRange(StartRange.location + StartRange.length, EndRange.location - (StartRange.location + StartRange.length))];
		}
		while (false);
		//NSLog(@"imageUrl: >%@<\n", imageUrl);

		// If successfully uploaded
		if ([imageUrl length] > 0)
		{
			// Set clipboard contents to a string
			[self setPasteboardString: imageUrl];

			// Display a popup balloon
			//[self toggleAttachedWindowAtPoint:notificationPosition message:@"Image uploaded successfully,\nits URL is now in your Clipboard." withUrl:[NSURL URLWithString:imageUrl]];
			[self displayUserNotification: imageUrl failReason: nil];
		}
		else
		{
			NSLog(@"Upload failed.\n>%@<\n", returnString);

			// Display a popup balloon
			//[self toggleAttachedWindowAtPoint:notificationPosition message:[NSString stringWithFormat:@"Image upload failed.\n%@", [returnString substringFromIndex: 8]] withUrl:nil];
			[self displayUserNotification: nil failReason: [returnString substringFromIndex: 8]];
		}

		requestedUploadAction = 0;
	}
}

- (void)displayUserNotification: (NSString *)imageUrl failReason: (NSString *)failReason
{
	NSUserNotification * notification = [[NSUserNotification alloc] init];
	if (   nil != imageUrl
		&& [imageUrl length] > 0)
	{
		[notification setTitle: @"Image Uploaded"];
		[notification setInformativeText: @"Its URL is now in your Clipboard."];
		[notification setUserInfo: [NSDictionary dictionaryWithObject: imageUrl forKey: @"ImageUrl"]];
	}
	else
	{
		[notification setTitle: @"Image Upload Failed"];
		[notification setInformativeText: failReason];
	}
	[notification setSoundName: NSUserNotificationDefaultSoundName];

	NSUserNotificationCenter * center = [NSUserNotificationCenter defaultUserNotificationCenter];
	[center deliverNotification: notification];
}

- (void)toggleAttachedWindowAtPoint:(NSPoint)pt message:(NSString *)message withUrl:(NSURL *)Url
{
	if (nil != attachedWindow && ![attachedWindow isVisible])
	{
		attachedWindow = nil;
	}

    // Attach/detach window.
    if (nil == attachedWindow)
	{
		//NSLog(@"Created window at %f, %f\n", pt.x, pt.y);
        attachedWindow = [[MAAttachedWindow alloc] initWithView:view 
                                                attachedToPoint:pt 
                                                       inWindow:nil 
                                                         onSide:MAPositionBottom 
                                                     atDistance:5.0
														withUrl:Url];
        [textField setTextColor:[attachedWindow borderColor]];
		[textField setStringValue:message];
		//[textField sizeToFit];
        [attachedWindow makeKeyAndOrderFront:self];
    }
	else
	{
		[attachedWindow setAlphaValue:1.0];
	}

	// Stop old timers
	if (nil != closeTimer)
	{
		[closeTimer invalidate];
		closeTimer = nil;
	}
	if (nil != repeatingTimer)
	{
		[repeatingTimer invalidate];
		self->repeatingTimer = nil;
	}

	NSTimer * timer = [NSTimer scheduledTimerWithTimeInterval:3.0
									 target:self
								   selector:@selector(closePopup)
								   userInfo:self
									repeats:NO];
	self->closeTimer = timer;
}

- (IBAction)closePopup
{
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.01
										target:self
									  selector:@selector(keepHidingPopup)
									  userInfo:nil
									   repeats:YES];
	self->repeatingTimer = timer;
}

- (IBAction)keepHidingPopup
{
	if ([attachedWindow alphaValue] > 0.02)
	{
		[attachedWindow setAlphaValue: [attachedWindow alphaValue] - 0.02];
	}
	else
	{
		if (nil != attachedWindow)
		{
			[attachedWindow orderOut:self];
			//[attachedWindow release];
			attachedWindow = nil;
		}
		
		// Stop old timers
		if (nil != closeTimer)
		{
			[closeTimer invalidate];
			closeTimer = nil;
		}
		if (nil != repeatingTimer)
		{
			[repeatingTimer invalidate];
			self->repeatingTimer = nil;
		}
	}
}

/*- (IBAction)openMenu:(id)sender
{
	//[statusItem popUpStatusItemMenu:statusMenu];
	
	// Display a popup balloon
	NSRect frame = [[[NSApp currentEvent] window] frame];
	NSPoint pt = NSMakePoint(NSMidX(frame), NSMinY(frame));
	[self toggleAttachedWindowAtPoint:pt message:@"Blah" withUrl:nil];
}*/

- (void)conversionPngThreadMethod
{
	if (1 == sourceImageDataType)
	{
		if ([conversionPngThread isCancelled])
		{
			return;
		}
		targetImageDataPng = sourceImageData;
		targetImageDataExistsPng = true;
	}
	else if (2 == sourceImageDataType)
	{
		NSBitmapImageRep * bitmap = [NSBitmapImageRep imageRepWithData: sourceImageData];
		NSData * data = [bitmap representationUsingType: NSPNGFileType properties: nil];
		if ([conversionPngThread isCancelled])
		{
			return;
		}
		targetImageDataPng = data;
		targetImageDataExistsPng = true;
	}
    else if ( 3 == sourceImageDataType ) {
        
        NSData * data = sourceImageData;
 		if ([conversionPngThread isCancelled])
		{
			return;
		}
        targetImageDataPng = data;
		targetImageDataExistsPng = true;
        
    }
	
	ItemAndTitle * object = [ItemAndTitle new];
	object->item = createPrivateShareMenuItem;
	object->title = [NSString stringWithFormat:@"Create Private Share (%lu KiB)", [targetImageDataPng length] / 1024];
    
    ItemAndTitle * publicObject = [ItemAndTitle new];
	publicObject->item = createPublicShareMenuItem;
	publicObject->title = [NSString stringWithFormat:@"Create Public Share (%lu KiB)", [targetImageDataPng length] / 1024];

    ItemAndTitle * shoutableObject = [ItemAndTitle new];
	shoutableObject->item = createShoutableShareMenuItem;
	shoutableObject->title = [NSString stringWithFormat:@"Create Shoutable Share (%lu KiB)", [targetImageDataPng length] / 1024];
   
    
	[self performSelectorOnMainThread:@selector(changeMenuTitle:)withObject:object waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(changeMenuTitle:)withObject:publicObject waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(changeMenuTitle:)withObject:shoutableObject waitUntilDone:YES];

}


- (IBAction)changeMenuTitle:(ItemAndTitle *)object
{
	[object->item setTitle:object->title];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if (item == createPrivateShareMenuItem)
	{
		// Update notificationPosition
		NSRect frame = [[[NSApp currentEvent] window] frame];
		notificationPosition = NSMakePoint(NSMidX(frame), NSMinY(frame));

		// Stop previous threads
		if (nil != conversionPngThread)
		{
			[conversionPngThread cancel];
		}

		// Figure out clipboard contents
		NSPasteboard * pb = [NSPasteboard generalPasteboard];
		NSData * data;
		if (nil != (data = [pb dataForType: NSPasteboardTypePNG]))
		{
			sourceImageDataType = 1;
			sourceImageData = data;
			targetImageDataExistsPng = false;
			targetImageDataPng = nil;
			targetImageDataExistsJpg = false;
			targetImageDataJpg = nil;
		}
		else if (nil != (data = [pb dataForType: NSPasteboardTypeTIFF]))
		{
			sourceImageDataType = 2;
			sourceImageData = data;
			targetImageDataExistsPng = false;
			targetImageDataPng = nil;
			targetImageDataExistsJpg = false;
			targetImageDataJpg = nil;
		}
		else if (nil != (data = [pb dataForType: NSPasteboardTypeString]))
        {
            NSString * dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            sourceImageDataType = 3;
            sourceImageData = data;
            targetImageDataExistsPng = false;
			targetImageDataPng = nil;
			targetImageDataExistsJpg = false;
			targetImageDataJpg = nil;
        
        }
		else
		{
			sourceImageDataType = 0;
			sourceImageData = nil;
			targetImageDataExistsPng = false;
			targetImageDataPng = nil;
			targetImageDataExistsJpg = false;
			targetImageDataJpg = nil;
		}

		// If there is an image in clipboard, enable menu items
		if ( sourceImageDataType == 1 || sourceImageDataType == 2)
		{
			[item setTitle:@"Create Private Share"];

			// Start conversion threads
			conversionPngThread = [[NSThread alloc] initWithTarget:self selector:@selector(conversionPngThreadMethod) object:nil];
			[conversionPngThread start];

			return YES;
		}
        else if ( sourceImageDataType == 3 )
        {
            conversionPngThread = [[NSThread alloc] initWithTarget:self selector:@selector(conversionPngThreadMethod) object:nil];
			[conversionPngThread start];
            return YES;
        }
		else
		{
			[item setTitle:@"No Image in Clipboard"];
			return NO;
		}
	}
	else if (item == createPublicShareMenuItem)
	{
		[item setHidden: ![createPrivateShareMenuItem isEnabled]];
		[item setTitle:@"Create Public Share"];


		return YES;
	}
    else if (item == createShoutableShareMenuItem)
	{
		[item setHidden: ![createPrivateShareMenuItem isEnabled]];
		[item setTitle:@"Create Shoutable Share"];
        
        
		return YES;
	}


    
    
	return YES;
}

- (void)awakeFromNib
{
}

@end


@implementation MyWindowController

- (id)init
{
    //self = [super initWithWindowNibName:@"SettingsWindow"];
    //if(self)
    //{
    //    //initialize stuff
    //}
    return self;
}
-(void)setAppDelegate:(NSApplication *)app {
    appDelegate = app;
}
//this is a simple override of -showWindow: to ensure the window is always centered
-(IBAction)showWindow:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *apiUsername    = [defaults stringForKey:@"apiUsername"];
    if (apiUsername == nil) apiUsername = @"mericson";
    
    NSString *apiKey    = [defaults stringForKey:@"apiKey"];
    if (apiKey == nil) apiKey = @"enter your api key here";
    
    NSString *apiUrl    = [defaults stringForKey:@"apiUrl"];
    if (apiUrl == nil) apiUrl = @"http://localhost:4567";
    
    [settingsUsername setStringValue:apiUsername];
    [settingsApiKey setStringValue:apiKey];
    [settingsApiUrl setStringValue:apiUrl];

    [[self window] center];
    [super showWindow:sender];
    [[self window] makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

/*-(void)setUsernameAndApiKey: (NSString*)username apiKey:(NSString *)key
{
    apiUsername = username;
    apiKey = key;
}*/

-(IBAction)saveUserSettings:(id)sender;
{
    NSLog( @"Saving User Settings");
    NSString *apiUsername = [settingsUsername stringValue];
    NSString *apiKey = [settingsApiKey stringValue];
    NSString *apiUrl = [settingsApiUrl stringValue];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:apiUsername forKey:@"apiUsername"];
    [prefs setObject:apiKey forKey:@"apiKey"];
    [prefs setObject:apiUrl forKey:@"apiUrl"];

    [prefs synchronize];
    
    [[self window] close];
}

-(IBAction)cancelSettings:(id)sender
{
    NSLog( @"Cancelling User Settings");
    [[self window] close];
}



-(void)awakeFromNib
{
    NSLog( @"Awaking from Nib");

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *apiUsername    = [defaults stringForKey:@"apiUsername"];
    if (apiUsername == nil) apiUsername = @"mericson";
    
    NSString *apiKey    = [defaults stringForKey:@"apiKey"];
    if (apiKey == nil) apiKey = @"enter your api key here";
    
    NSString *apiUrl    = [defaults stringForKey:@"apiUrl"];
    if (apiUrl == nil) apiUrl = @"http://localhost:4567";
    
    [settingsUsername setStringValue:apiUsername];
    [settingsApiKey setStringValue:apiKey];
    [settingsApiUrl setStringValue:apiUrl];

}

@end


