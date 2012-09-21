//
// Cordova Calendar Plugin
// Author: Felix Montanez 
// Created: 01-17-2012
//
// Contributors:
// Michael Brooks


function calendarPlugin()
{
}



//calendarPlugin.prototype.createEvent = function(title,location,notes,startDate,endDate,calendarName) {
//    console.log("creating event");
//    cordova.exec(null,null,"calendarPlugin","createEvent", [title,location,notes,startDate,endDate,calendarName]);
//};
calendarPlugin.prototype.createEvent = function(callback){
    console.log("create event");
    this.resultCallback = callback;
    this.createEventWithUI.apply(this,[]);
};

calendarPlugin.prototype.createEventWithUI = function(uid){
    // TODO edit this so it can optionally edit an event
    uid = uid || null;
    console.log("creating event with UI");
    cordova.exec(null, null, "calendarPlugin", "createEventWithUI", [uid]);
};

calendarPlugin.prototype.getCalendarList = function(response, err) {
    console.log("getting calendars");
    cordova.exec(response, err, "calendarPlugin", "getCalendarList",[]);
};

calendarPlugin.prototype.getEventList = function(response, err) {
    console.log("getting eventss");
    // TODO modify this to take a date range
    cordova.exec(response, err, "calendarPlugin", "findEvent",[]);
};

calendarPlugin.prototype.getFullCalendarList = function(response, err) {
    console.log("getting full calendars");
    cordova.exec(response, err, "calendarPlugin", "getFullCalendarList", []);
};

calendarPlugin.prototype._didFinishWithResult = function(res) {
    this.resultCallback(res);
};
// More methods will need to be added like fetch events, delete event, edit event

calendarPlugin.install = function()
{
    if(!window.plugins)
    {
        window.plugins = {};
    }
    
    window.plugins.calendarPlugin = new calendarPlugin();
    return window.plugins.calendarPlugin;
};

cordova.addConstructor(calendarPlugin.install);
