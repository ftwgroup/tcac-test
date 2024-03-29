//
//  calendarPlugin.m
//  Author: Felix Montanez
//  Date: 01-17-2011
//  Notes: 


#import "calendarPlugin.h"
#import <EventKitUI/EventKitUI.h>
#import <EventKit/EventKit.h>

@implementation calendarPlugin
@synthesize eventStore;
@synthesize defaultCalendar;


- (CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (calendarPlugin*)[super initWithWebView:theWebView];
    if (self) {
		//[self setup];
    }
    return self;
}

-(void)createEvent:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options
{
    //Get the Event store object
    EKEvent *myEvent;
    EKEventStore *store;
    
    store = [[EKEventStore alloc] init];
    myEvent = [EKEvent eventWithEventStore: store];
    
    NSString* title         = [arguments objectAtIndex:1];
    NSString* location      = [arguments objectAtIndex:2];
    NSString* message       = [arguments objectAtIndex:3];
    NSString* startDate     = [arguments objectAtIndex:4];
    NSString* endDate       = [arguments objectAtIndex:5];
    NSString* calendarTitle = [arguments objectAtIndex:6];
    
    EKCalendar* calendar = nil;
    if(calendarTitle == nil){
        calendar = store.defaultCalendarForNewEvents;
    } else {
        NSIndexSet* indexes = [store.calendars indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            *stop = false;
            EKCalendar* cal = (EKCalendar*)obj;
            if(cal.title == calendarTitle){
                *stop = true;
            }
            return *stop;
        }];
        if (indexes.count == 0) {
            calendar = store.defaultCalendarForNewEvents;
        } else {
            calendar = [store.calendars objectAtIndex:[indexes firstIndex]];
        }
    }
    
    //creating the dateformatter object
    NSDateFormatter *sDate = [[[NSDateFormatter alloc] init] autorelease];
    [sDate setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *myStartDate = [sDate dateFromString:startDate];
    
    
    NSDateFormatter *eDate = [[[NSDateFormatter alloc] init] autorelease];
    [eDate setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *myEndDate = [eDate dateFromString:endDate];
    
    
    myEvent.title = title;
    myEvent.location = location;
    myEvent.notes = message;
    myEvent.startDate = myStartDate;
    myEvent.endDate = myEndDate;
    myEvent.calendar = calendar;
    
    
    EKAlarm *reminder = [EKAlarm alarmWithRelativeOffset:-2*60*60];
    
    [myEvent addAlarm:reminder];
    
    NSError *error;
    BOOL saved = [store saveEvent:myEvent span:EKSpanThisEvent
                            error:&error];
    if (saved) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:@"Saved to Calendar" delegate:self
                                              cancelButtonTitle:@"Thank you!"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        
        
    }
}

-(void)createEventWithUI:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options
{
    NSString *arg = [arguments objectAtIndex:0];
    // Get the event store object
    EKEventStore *store = [[EKEventStore alloc] init];
    
    // request permission to access the calendars, this will only show the
    // pop-up if you are asking permission for the first time.
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        NSLog(@"Permission granted: %s", granted ? "true" : "false");
        // You can return from a block like any other function
    }];
    
    // Create the EditViewController
    EKEventEditViewController *controller = [[EKEventEditViewController alloc] init];
    controller.eventStore = store;
    if (arg == @"INVALID"){
        controller.event = [store eventWithIdentifier:arg];
    }
    
    controller.editViewDelegate = self;
    
    if (controller != nil) {
        [self.viewController presentModalViewController:controller animated:YES];
    }
    
    [controller release];
}

// the delegate to dismiss the modal view
-(void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
    int webResult = 0;
    
    switch (action) {
        case EKEventEditViewActionCanceled:
            webResult = 0;
            break;
        case EKEventEditViewActionSaved:
            webResult = 1;
            break;
        case EKEventEditViewActionDeleted:
            webResult = 2;
            break;
        default:
            webResult = 3;
            break;
    }
    [self.viewController dismissModalViewControllerAnimated:YES];
    //Not necessarily correct;
    NSString *jsString = [[NSString alloc] initWithFormat:@"window.plugins.calendarPlugin._didFinishWithResult(%d);",webResult];
    [self writeJavascript:jsString];
    [jsString release];
}
/***** NOT YET IMPLEMENTED BELOW ************/

//-(void)deleteEvent:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options {}

/*
-(void)findEvent:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options {
 
 EKEventStore* store = [[EKEventStore alloc] init];
 EKEvent* myEvent = [EKEvent eventWithEventStore: store];
 
 NSString *startSearchDate  = [arguments objectAtIndex:1];
 NSString *endSearchDate    = [arguments objectAtIndex:2];
 
 
 //creating the dateformatter object
 NSDateFormatter *sDate = [[[NSDateFormatter alloc] init] autorelease];
 [sDate setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
 NSDate *myStartDate = [sDate dateFromString:startSearchDate];
 
 
 NSDateFormatter *eDate = [[[NSDateFormatter alloc] init] autorelease];
 [eDate setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
 NSDate *myEndDate = [eDate dateFromString:endSearchDate];
 
 
 // Create the predicate
 NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:myStartDate endDate:myEndDate calendars:defaultCalendar]; 
 
 
 // eventStore is an instance variable.
 // Fetch all events that match the predicate.
 NSArray *events = [eventStore eventsMatchingPredicate:predicate];
 [self setEvents:events];
 
 
}
 */
-(void)findEvent:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options
{
    NSLog(@"In plugin method findEvent");
    NSString *callback = [arguments objectAtIndex:0];
    
    EKEventStore *store = [[EKEventStore alloc] init];
    
    NSDate *startDate = [NSDate date];
    NSDate *endDate = [NSDate distantFuture];
    
    NSPredicate *predicate = [store predicateForEventsWithStartDate:startDate endDate:endDate calendars:nil];
    
    NSArray *events = [store eventsMatchingPredicate:predicate];
    NSString *js = nil;

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    
    if (events.count > 0) {
        NSMutableArray *returnArray= [NSMutableArray arrayWithCapacity:events.count];
        for (EKEvent *event in events) {
            
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:event.eventIdentifier,@"identifier",[dateFormatter stringFromDate:event.startDate],@"startDate", event.title,@"title",nil];
            [returnArray addObject:dict];
        }
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:returnArray];
        js = [result toSuccessCallbackString:callback];
    } else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no events found"];
        js = [result toErrorCallbackString:callback];
    }
    [self writeJavascript:js];
    
}
-(void)getCalendarList:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options
{
    NSLog(@"In plugin method getCalendarList");
    NSString *callback = [arguments objectAtIndex:0];
    EKEventStore* store = [[EKEventStore alloc] init];
    NSString* js = nil;
    if (store != nil && store.calendars.count > 0) {
        NSMutableArray *titles = [[store.calendars valueForKey:@"title"] mutableCopy];
        NSLog(@"Found %i calendars", titles.count);
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:titles];
        js = [result toSuccessCallbackString:callback];
    } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no calendars found"];
        js = [result toErrorCallbackString:callback];
    }
    [self writeJavascript:js];
}

-(void)getFullCalendarList:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options
{
    NSLog(@"In plugin method getFullCalendarList");
    NSString *callback = [arguments objectAtIndex:0];
    EKEventStore *store = [[EKEventStore alloc] init];
    NSString *js = nil;
    
    // Get all calendars
    NSMutableArray *calendarList = [[store calendars] mutableCopy];
    // Fails because a string is expected within the array.
    
    if (store != nil && calendarList.count > 0) {
        NSLog(@"Found %i calendars", calendarList.count);
        //NSLog()
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:calendarList];
        js = [result toSuccessCallbackString:callback];
    } else {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no calendars found"];
        js = [result toErrorCallbackString:callback];
    }
    [self writeJavascript:js];
}
 
/*-(void)modifyEvent:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options{
 EKEventViewController *eventViewController = [[EKEventViewController alloc] init];
 eventViewController.event = myEvent;
 eventViewController.allowsEditing = YES;
 navigationController we
= [[UINavigationController alloc]
 initWithRootViewController:eventViewController];
 [eventViewController release];
} */


//delegate method for EKEventEditViewDelegate
//-(void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action {
//    [(UIViewController*)self dismissModalViewControllerAnimated:YES];
//    [self release];
//}
@end
