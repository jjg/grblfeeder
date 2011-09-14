//
//  AppController.h
//  AMSerialTest
//

#import <Cocoa/Cocoa.h>
#import "AMSerialPort.h"


@interface AppController : NSObject {
	IBOutlet NSTextField *inputTextField;
	IBOutlet NSTextField *deviceTextField;
	IBOutlet NSTextView *outputTextView;
    IBOutlet NSWindow *theWindow;
    IBOutlet NSProgressIndicator *runProgress;
    IBOutlet NSTextField *stepIndicator;
    IBOutlet NSTextField *instructionIndicator;
	AMSerialPort *port;
}

- (AMSerialPort *)port;
- (void)setPort:(AMSerialPort *)newPort;


- (IBAction)listDevices:(id)sender;

- (IBAction)chooseDevice:(id)sender;

- (IBAction)send:(id)sender;

//  new code
@property (nonatomic, retain) NSWindow *theWindow;
@property (nonatomic, retain) NSProgressIndicator *runProgress;
@property (nonatomic, retain) NSTextField *stepIndicator;
@property (nonatomic, retain) NSTextField *instructionIndicator;
-(IBAction)openFile:(id)sender;
-(void) showFileOpenSheet;
//-(void)filePanelDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
-(void)filePanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
-(NSArray *)fileTypesArray;
-(void)setFileTypesArray:(NSArray*) anArray;
-(NSString *) userDirectory;
-(void) setUserDirectoryFromFilename: (NSString *) aFilename;
//-(id)theWindow;
NSString *readLineAsNSString(FILE *file);
-(IBAction)runCode:(id)sender;
-(IBAction)stopCode:(id)sender;
-(IBAction)sendString:(NSString *) commandString;

@end
