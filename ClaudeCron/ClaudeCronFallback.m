#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

static NSString *CronMarker = @"# CLAUDE_CRON:";

static NSString *Run(NSString *path, NSArray *args, NSString *input) {
    NSTask *task = [NSTask new]; NSPipe *out = [NSPipe pipe]; NSPipe *in = [NSPipe pipe];
    task.launchPath = path; task.arguments = args; task.standardOutput = out; task.standardError = out;
    if (input) task.standardInput = in;
    @try { [task launch]; if (input) { [[in fileHandleForWriting] writeData:[input dataUsingEncoding:NSUTF8StringEncoding]]; [[in fileHandleForWriting] closeFile]; } [task waitUntilExit]; }
    @catch (__unused id e) { return @""; }
    return [[NSString alloc] initWithData:[[out fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] ?: @"";
}

static void Submit(BOOL launchClaude) {
    NSString *script = launchClaude ? @"tell application \"Claude\" to activate\ndelay 1\ntell application \"System Events\"\nset frontApp to name of first application process whose frontmost is true\nif frontApp is \"Claude\" then key code 36\nend tell" : @"tell application \"System Events\"\nset frontApp to name of first application process whose frontmost is true\nif frontApp is \"Claude\" then key code 36\nend tell";
    Run(@"/usr/bin/osascript", @[@"-e", script], nil);
}

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource>
@property NSWindow *window; @property NSDatePicker *picker; @property NSTableView *table; @property NSMutableArray<NSString *> *times;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)n {
    if ([[[NSProcessInfo processInfo] arguments] containsObject:@"--submit-now"]) { dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 300000000), dispatch_get_main_queue(), ^{ Submit(![[[NSProcessInfo processInfo] arguments] containsObject:@"--no-launch"]); [NSApp terminate:nil]; }); return; }
    self.times = [NSMutableArray array]; [self refresh];
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,430,500) styleMask:(NSWindowStyleMaskTitled|NSWindowStyleMaskClosable) backing:NSBackingStoreBuffered defer:NO]; self.window.title = @"Claude Cron"; [self.window center];
    NSView *v = self.window.contentView; NSTextField *title = [NSTextField labelWithString:@"Claude Cron"]; title.font = [NSFont boldSystemFontOfSize:22]; title.frame = NSMakeRect(24,445,380,30); [v addSubview:title];
    [v addSubview:[NSTextField labelWithString:@"Submit Claude prompts on a daily schedule."]]; [[v subviews].lastObject setFrame:NSMakeRect(24,420,380,20)];
    NSTextField *label = [NSTextField labelWithString:@"Submit at:"]; label.frame = NSMakeRect(24,380,75,24); [v addSubview:label];
    self.picker = [[NSDatePicker alloc] initWithFrame:NSMakeRect(95,375,150,32)]; self.picker.datePickerElements = NSDatePickerElementFlagHourMinute; self.picker.datePickerStyle = NSDatePickerStyleTextField; [v addSubview:self.picker];
    NSButton *schedule = [NSButton buttonWithTitle:@"Schedule" target:self action:@selector(schedule:)]; schedule.frame = NSMakeRect(270,375,110,32); [v addSubview:schedule];
    NSTextField *scheduled = [NSTextField labelWithString:@"Scheduled"]; scheduled.font = [NSFont boldSystemFontOfSize:14]; scheduled.frame = NSMakeRect(24,335,120,20); [v addSubview:scheduled];
    self.table = [[NSTableView alloc] initWithFrame:NSMakeRect(24,170,356,155)]; NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:@"time"]; col.width=290; [self.table addTableColumn:col]; self.table.dataSource=self; NSScrollView *scroll=[[NSScrollView alloc] initWithFrame:NSMakeRect(24,170,356,155)]; scroll.documentView=self.table; scroll.hasVerticalScroller=YES; [v addSubview:scroll];
    NSButton *test=[NSButton buttonWithTitle:@"Test Now" target:self action:@selector(test:)]; test.frame=NSMakeRect(24,125,100,32); [v addSubview:test];
    NSButton *settings=[NSButton buttonWithTitle:@"Open Accessibility Settings" target:self action:@selector(settings:)]; settings.frame=NSMakeRect(150,125,220,32); [v addSubview:settings];
    NSTextField *note=[NSTextField labelWithString:@"Accessibility: "]; note.frame=NSMakeRect(24,85,360,20); note.tag=8; [v addSubview:note]; [self updateNote]; [self.window makeKeyAndOrderFront:nil];
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)t { return self.times.count; }
- (NSView *)tableView:(NSTableView *)t viewForTableColumn:(NSTableColumn *)c row:(NSInteger)r { NSTextField *x=[NSTextField labelWithString:self.times[r]]; NSButton *d=[NSButton buttonWithTitle:@"Delete" target:self action:@selector(delete:)]; d.tag=r; NSView *v=[[NSView alloc] initWithFrame:NSMakeRect(0,0,c.width,24)]; [v addSubview:x]; x.frame=NSMakeRect(4,0,220,24); [v addSubview:d]; d.frame=NSMakeRect(230,0,65,24); return v; }
- (void)refresh { NSString *s=Run(@"/usr/bin/crontab", @[@"-l"], nil); [self.times removeAllObjects]; for (NSString *line in [s componentsSeparatedByString:@"\n"]) { NSRange r=[line rangeOfString:CronMarker]; if(r.location!=NSNotFound) [self.times addObject:[line substringWithRange:NSMakeRange(r.location+r.length,4)]]; } [self.times sortUsingSelector:@selector(compare:)]; if(self.table)[self.table reloadData]; }
- (void)writeCron:(NSArray *)lines { Run(@"/usr/bin/crontab", @[@"-"], [[lines componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"]); [self refresh]; }
- (void)schedule:(id)sender { NSDateComponents *c=[[NSCalendar currentCalendar] components:(NSCalendarUnitHour|NSCalendarUnitMinute) fromDate:self.picker.dateValue]; NSString *idv=[NSString stringWithFormat:@"%02ld%02ld",(long)c.hour,(long)c.minute]; if([self.times containsObject:idv])return; NSString *s=Run(@"/usr/bin/crontab", @[@"-l"], nil); NSMutableArray *lines=[NSMutableArray arrayWithArray:[s componentsSeparatedByString:@"\n"]]; [lines addObject:[NSString stringWithFormat:@"%ld %ld * * * /usr/bin/open -a \\\"Claude Cron\\\" --args --submit-now %@%@",(long)c.minute,(long)c.hour,CronMarker,idv]]; [self writeCron:lines]; }
- (void)delete:(NSButton *)b { NSString *idv=self.times[b.tag]; NSString *s=Run(@"/usr/bin/crontab", @[@"-l"], nil); NSMutableArray *lines=[NSMutableArray array]; for(NSString *line in [s componentsSeparatedByString:@"\n"]) if(![line containsString:[CronMarker stringByAppendingString:idv]])[lines addObject:line]; [self writeCron:lines]; }
- (void)test:(id)sender { Submit(YES); }
- (void)settings:(id)sender { [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"]]; }
- (void)updateNote { NSTextField *x=[self.window.contentView viewWithTag:8]; x.stringValue=[NSString stringWithFormat:@"Accessibility: %@", AXIsProcessTrusted()?@"Allowed":@"Not allowed — Claude Cron needs permission to press Return."]; }
@end

int main(int argc, const char **argv) { @autoreleasepool { NSApplication *app=[NSApplication sharedApplication]; AppDelegate *d=[AppDelegate new]; app.delegate=d; [app setActivationPolicy:NSApplicationActivationPolicyRegular]; [app run]; } return 0; }
