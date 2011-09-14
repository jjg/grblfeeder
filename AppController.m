//
//  AppController.m
//  AMSerialTest
//
//		2009-09-09		Andreas Mayer
//		- fixed memory leak in -serialPortReadData:

#include <stdio.h>
#import "AppController.h"
#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"

@implementation AppController
@synthesize theWindow;
@synthesize runProgress;
@synthesize stepIndicator;
@synthesize instructionIndicator;

NSArray *fileTypesArray;
NSString *userDirectory;
NSMutableArray *commandQueue;
bool runningCode;
int codeIndex;

- (void)awakeFromNib
{
	[deviceTextField setStringValue:@"/dev/cu.usbmodem1a21"]; // internal modem
	[inputTextField setStringValue: @"$"]; // will ask for modem type

	// register for port add/remove notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddPorts:) name:AMSerialPortListDidAddPortsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemovePorts:) name:AMSerialPortListDidRemovePortsNotification object:nil];
	[AMSerialPortList sharedPortList]; // initialize port list to arm notifications
    
    //[commandQueue initWithCapacity:10];
    //commandQueue = [[NSMutableArray alloc] init];
    
    codeIndex = 0;
    runningCode = NO;
    
    [self initPort];
}


- (AMSerialPort *)port
{
    return port;
}

- (void)setPort:(AMSerialPort *)newPort
{
    id old = nil;

    if (newPort != port) {
        old = port;
        port = [newPort retain];
        [old release];
    }
}


- (void)initPort
{
	NSString *deviceName = [deviceTextField stringValue];
	if (![deviceName isEqualToString:[port bsdPath]]) {
		[port close];

		[self setPort:[[[AMSerialPort alloc] init:deviceName withName:deviceName type:(NSString*)CFSTR(kIOSerialBSDModemType)] autorelease]];
		
		// register as self as delegate for port
		[port setDelegate:self];
		
		[outputTextView insertText:@"attempting to open port\r"];
		[outputTextView setNeedsDisplay:YES];
		[outputTextView displayIfNeeded];
		
		// open port - may take a few seconds ...
		if ([port open]) {
			
			[outputTextView insertText:@"port opened\r"];
			[outputTextView setNeedsDisplay:YES];
			[outputTextView displayIfNeeded];

			// listen for data in a separate thread
			[port readDataInBackground];
			
		} else { // an error occured while creating port
			[outputTextView insertText:@"couldn't open port for device "];
			[outputTextView insertText:deviceName];
			[outputTextView insertText:@"\r"];
			[outputTextView setNeedsDisplay:YES];
			[outputTextView displayIfNeeded];
			[self setPort:nil];
		}
	}
}

- (void)serialPortReadData:(NSDictionary *)dataDictionary
{
	// this method is called if data arrives 
	// @"data" is the actual data, @"serialPort" is the sending port
	AMSerialPort *sendPort = [dataDictionary objectForKey:@"serialPort"];
	NSData *data = [dataDictionary objectForKey:@"data"];
	if ([data length] > 0) {
		NSString *text = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		[outputTextView insertText:text];
		[text release];
        
        //  send next code
        //  set the running flag
        if(runningCode){
            if(codeIndex < [commandQueue count]){
                
                NSLog(@"Command: %@", [commandQueue objectAtIndex:codeIndex]);
                
                [instructionIndicator setStringValue:[commandQueue objectAtIndex:codeIndex]];
                
                [stepIndicator setStringValue:[NSString stringWithFormat:@"%d",codeIndex]];
                [runProgress incrementBy:1];
                [runProgress displayIfNeeded];
                
                //  send the comand to GRBL
                [self sendString:[commandQueue objectAtIndex:codeIndex]];
                
                codeIndex++;
                
            } else {
                
                [stepIndicator setStringValue:@"0"];
                [instructionIndicator setStringValue:@"Finished"];
                [runProgress stopAnimation:self];
                runningCode = NO;
                codeIndex = 0; 
            }
        }
        
		// continue listening
		[sendPort readDataInBackground];
	} else { // port closed
		[outputTextView insertText:@"port closed\r"];        
	}
	[outputTextView setNeedsDisplay:YES];
	[outputTextView displayIfNeeded];
}


- (void)didAddPorts:(NSNotification *)theNotification
{
	[outputTextView insertText:@"didAddPorts:"];
	[outputTextView insertText:@"\r"];
	[outputTextView insertText:[[theNotification userInfo] description]];
	[outputTextView insertText:@"\r"];
	[outputTextView setNeedsDisplay:YES];
}

- (void)didRemovePorts:(NSNotification *)theNotification
{
	[outputTextView insertText:@"didRemovePorts:"];
	[outputTextView insertText:@"\r"];
	[outputTextView insertText:[[theNotification userInfo] description]];
	[outputTextView insertText:@"\r"];
	[outputTextView setNeedsDisplay:YES];
}


- (IBAction)listDevices:(id)sender
{
	// get an port enumerator
	NSEnumerator *enumerator = [AMSerialPortList portEnumerator];
	AMSerialPort *aPort;
	while (aPort = [enumerator nextObject]) {
		// print port name
		[outputTextView insertText:[aPort name]];
		[outputTextView insertText:@":"];
		[outputTextView insertText:[aPort bsdPath]];
		[outputTextView insertText:@"\r"];
	}
	[outputTextView setNeedsDisplay:YES];
}

- (IBAction)chooseDevice:(id)sender
{
	// new device selected
	[self initPort];
}

- (IBAction)send:(id)sender
{
	NSString *sendString = [[inputTextField stringValue] stringByAppendingString:@"\r"];

	if(!port) {
		// open a new port if we don't already have one
		[self initPort];
	}

	if([port isOpen]) { // in case an error occured while opening the port
		[port writeString:sendString usingEncoding:NSUTF8StringEncoding error:NULL];
	}
}

- (IBAction)sendString:(NSString *) commandString
{
	//NSString *sendString = [[inputTextField stringValue] stringByAppendingString:@"\r"];
    
	if(!port) {
		// open a new port if we don't already have one
		[self initPort];
	}
    
	if([port isOpen]) { // in case an error occured while opening the port
		[port writeString:commandString usingEncoding:NSUTF8StringEncoding error:NULL];
	}
    
    [outputTextView setNeedsDisplay:YES];
    [outputTextView displayIfNeeded];
}

//  new code
-(NSArray *)fileTypesArray
{
    return fileTypesArray;
}

-(void)setFileTypesArray:(NSArray*) anArray;
{
    fileTypesArray = anArray;
}

-(NSString *) userDirectory
{
    return userDirectory;
}

-(void) setUserDirectoryFromFilename: (NSString *) aFilename
{
    userDirectory = aFilename;
}
/*
-(id)window
{
    return [self window];
}
*/
-(void)openFile:(id)sender{
    [self showFileOpenSheet];
}

-(void) showFileOpenSheet
{
    NSOpenPanel * panel = [NSOpenPanel openPanel];
    
    [self setFileTypesArray:[NSArray arrayWithObjects:@"txt",@"nc",nil]];
    
    [panel beginSheetForDirectory:[self userDirectory] file:nil types:[self fileTypesArray] modalForWindow:[self theWindow] modalDelegate:self didEndSelector:@selector(filePanelDidEnd:returnCode:contextInfo:)
                      contextInfo:nil];
}


-(IBAction)runCode:(id)sender
{
    //  set the running flag
    runningCode = YES;
    
    //  init the indicators
    [instructionIndicator setStringValue:@""];
    [stepIndicator setStringValue:@""];
    
    //  init the progress bar
    [runProgress setDoubleValue:0];
    [runProgress setMinValue:0];
    [runProgress setMaxValue:[commandQueue count]];
     
    //  send the first instruction
    codeIndex = 0;
    NSLog(@"Command: %@", [commandQueue objectAtIndex:codeIndex]);
    [instructionIndicator setStringValue:[commandQueue objectAtIndex:codeIndex]];
    [stepIndicator setStringValue:[NSString stringWithFormat:@"%d",codeIndex]];
    [self sendString:[commandQueue objectAtIndex:codeIndex]];
}

-(IBAction)stopCode:(id)sender{
    runningCode = NO;
    codeIndex = 0;
    [instructionIndicator setStringValue:@"Stopped"];
    [stepIndicator setStringValue:@"0"];
    [runProgress setDoubleValue:0];
    [runProgress stopAnimation:self];
}

-(void)filePanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [self setUserDirectoryFromFilename:[sheet filename]];
    NSLog(@"Filename: %@", [self userDirectory]);
    
    //  load the file
    FILE *file = fopen([[self userDirectory] UTF8String], "r");
    
    //  init the command queue
    commandQueue = [[NSMutableArray alloc] init];
    
    // check for NULL
    while(!feof(file))
    {
        NSString *line = readLineAsNSString(file);
        // do stuff with line; line is autoreleased, so you should NOT release it (unless you also retain it beforehand)
        
        NSLog(@"Line: %@",line);
        
        if([line length] > 1){
            //line = [NSString stringWithFormat:@"%@\n\r", line];
        
            //  add the command to the array
            [commandQueue addObject:line];
        }
        
    }
    fclose(file);
    
}

NSString *readLineAsNSString(FILE *file)
{
    char buffer[4096];
    
    // tune this capacity to your liking -- larger buffer sizes will be faster, but
    // use more memory
    NSMutableString *result = [NSMutableString stringWithCapacity:2048];
    
    // Read up to 4095 non-newline characters, then read and discard the newline
    int charsRead;
    do
    {
        //if(fscanf(file, "%4095[^\n]%n%*c", buffer, &charsRead) == 1)
        //if(fscanf(file, "%s", buffer) == 1)
        if(fgets(buffer, 4095, file))
            [result appendFormat:@"%s", buffer];
        else
            break;
    } while(charsRead == 4095);
    
    return result;
}

@end
