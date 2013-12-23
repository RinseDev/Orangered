#import "ORPuller.h"

@implementation ORPuller

-(ORPuller *)init{
	if((self = [super init])){
		logger = [[ORLogger alloc] initFromSource:@"ORPuller.m"];
		possibleErrors = @[@"Received empty reply.", @"Timed out.", @"Download error.", @"You broke something!"];	
		[logger log:@"creating message puller object, should be running routine soon..."];

		[self loadCredentials];
	}//end if

	return self;
}//end init

-(ORPuller *)initWithUsername:(NSString *)user andPassword:(NSString *)pass{
	if((self = [super init])){
		logger = [[ORLogger alloc] initFromSource:@"ORPuller.m"];
		possibleErrors = @[@"Received empty reply.", @"Timed out.", @"Download error.", @"You broke something!"];
		[logger log:@"creating message puller object, should be running routine soon..."];

		username = user;
		password = pass;
	}

	return self;
}//end init2

-(void)loadCredentials{

	NSString *savedName = [[self settings] objectForKey:@"usernameText"];
	NSString *savedPass = [[self settings] objectForKey:@"passwordText"];
	if (!savedName || [savedName isEmpty] || !savedPass || [savedPass isEmpty]){
		[logger log:@"couldn't find any stored login information, taking a nap..."];
		return;
	}//end if

	username = savedName;
	password = savedPass;
}//end loadCredentials

-(void)run{
	if (!username || !password) {
		[logger log:@"couldn't find any stored login information, taking a nap..."];
		return;
	}///end if

	[logger log:@"preparing authentication credentials for Reddit..."];
	NSString *loginString = [@"http://www.reddit.com/api/login/" stringByAppendingString:username];
	NSURL *loginURL = [NSURL URLWithString:loginString];
	NSMutableURLRequest *loginRequest = [NSMutableURLRequest requestWithURL:loginURL];
	[loginRequest setHTTPShouldHandleCookies:YES];
	[loginRequest setHTTPMethod:@"POST"];

	NSString *loginRequestString = [NSString stringWithFormat:@"api_type=json&user=%@&passwd=%@", username, password];
	NSData *loginRequestBody = [loginRequestString dataUsingEncoding:NSUTF8StringEncoding];
	[loginRequest setHTTPBody:loginRequestBody];

	NSOperationQueue *loginQueue = [[NSOperationQueue alloc] init];
	[NSURLConnection sendAsynchronousRequest:loginRequest queue:loginQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		if ([data length] > 0 && error == nil)
			[self performSelectorOnMainThread:@selector(processHashData:) withObject:data waitUntilDone:NO];

		else if ([data length] == 0 && error == nil)
			[self performSelectorOnMainThread:@selector(processHashData:) withObject:[@"Received empty reply." dataUsingEncoding:NSUTF8StringEncoding] waitUntilDone:NO];

		else if (error != nil && error.code == NSURLErrorTimedOut)
			[self performSelectorOnMainThread:@selector(processHashData:) withObject:[@"Timed out." dataUsingEncoding:NSUTF8StringEncoding] waitUntilDone:NO];

		else if (error != nil)
			[self performSelectorOnMainThread:@selector(processHashData:) withObject:[@"Download error." dataUsingEncoding:NSUTF8StringEncoding] waitUntilDone:NO];

		else
			[self performSelectorOnMainThread:@selector(processHashData:) withObject:[@"You broke something!" dataUsingEncoding:NSUTF8StringEncoding] waitUntilDone:NO];
	}];

	[logger log:@"sent off information! Waiting for response..."];
}//end run

-(void)processHashData:(NSData *)data {

	[logger log:@"received response from Reddit, running it through the filter..."];

	NSString *loginResponseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	if([possibleErrors containsObject:loginResponseString]){
		[logger log:[NSString stringWithFormat:@"hit a problem while processing login data: %@.", loginResponseString]];
		[self quitAndHandleError:nil orMessage:loginResponseString];
		return;
	}

	[logger log:@"all seems well! Processing response from Reddit, pre-heating inbox..."];
	NSError *loginRequestError = nil;
	NSData *loginJSONData = [loginResponseString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *loginResults = [NSJSONSerialization JSONObjectWithData:loginJSONData options:0 error:&loginRequestError];
	if(loginRequestError){
		[logger log:[NSString stringWithFormat:@"hit a problem parsing (with response string: %@) login information: %@.", loginResponseString, loginRequestError]];
		[self quitAndHandleError:nil orMessage:loginResponseString];
		return;
	}
	
	modhash = [[[loginResults valueForKey:@"json"] valueForKey:@"data"] valueForKey:@"modhash"];
	NSArray *loginErrorResults = [[loginResults valueForKey:@"json"] valueForKey:@"errors"];
	if(loginErrorResults != nil && [loginErrorResults count] > 0){
		[self quitAndHandleError:nil orMessage:[NSString stringWithFormat:@"%@", loginErrorResults]];
		return;
	}

	[self loadUnread];
}//end retrieveHash


-(void)loadUnread{

	[logger log:@"and into the oven it goes! Preparing to pull unread messages from Reddit servers..."];
	NSString *unreadString = @"http://www.reddit.com/message/unread.json";
	NSURL *unreadURL = [NSURL URLWithString:unreadString];

	NSMutableURLRequest *unreadRequest = [NSMutableURLRequest requestWithURL:unreadURL];
	[unreadRequest setHTTPShouldHandleCookies:YES];
	[unreadRequest setHTTPMethod:@"GET"];

	NSOperationQueue *unreadQueue = [[NSOperationQueue alloc] init];
	[NSURLConnection sendAsynchronousRequest:unreadRequest queue:unreadQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){

		if ([data length] > 0 && error == nil)
			[self performSelectorOnMainThread:@selector(processUnreadData:) withObject:data waitUntilDone:NO];

		else if ([data length] == 0 && error == nil)
			[self performSelectorOnMainThread:@selector(processUnreadData:) withObject:[@"Received empty reply." dataUsingEncoding:NSUTF8StringEncoding] waitUntilDone:NO];

		else if (error != nil && error.code == NSURLErrorTimedOut)
			[self performSelectorOnMainThread:@selector(processUnreadData:) withObject:[@"Timed out." dataUsingEncoding:NSUTF8StringEncoding] waitUntilDone:NO];

		else if (error != nil)
			[self performSelectorOnMainThread:@selector(processUnreadData:) withObject:[@"Download error." dataUsingEncoding:NSUTF8StringEncoding] waitUntilDone:NO];

		else
			[self performSelectorOnMainThread:@selector(processUnreadData:) withObject:[@"You broke something!" dataUsingEncoding:NSUTF8StringEncoding] waitUntilDone:NO];
	}];

	[logger log:@"sent off a little birdie to pull the unread inbox. Waiting for response..."];
}//end unread

-(void)processUnreadData:(NSData *)data {

	NSString *unreadResponseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	if([possibleErrors containsObject:unreadResponseString]){
		[logger log:[NSString stringWithFormat:@"hit a problem processing unread data: %@", unreadResponseString]];
		[self quitAndHandleError:nil orMessage:unreadResponseString];
		return;
	}

	NSError *unreadRequestError = nil;
	NSData *unreadJSONData = [unreadResponseString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *unreadResults = [NSJSONSerialization JSONObjectWithData:unreadJSONData options:0 error:&unreadRequestError];
	if(unreadRequestError){
		[logger log:[NSString stringWithFormat:@"hit a problem parsing unread data:%@", unreadRequestError]];
		[self quitAndHandleError:nil orMessage:unreadResponseString];
		return;
	}

	[logger log:@"finished all communications with Reddit servers! Formatting to ship off to the Notification Center..."];
	[self searchForUnreadWithArray:[[unreadResults valueForKey:@"data"] valueForKey:@"children"]];
}


-(void)searchForUnreadWithArray:(NSArray *)array {

	NSMutableArray *unreads = [[NSMutableArray alloc] init];
	for(NSDictionary *entry in array){
		NSDictionary *messagesDeep = [entry valueForKey:@"data"];

		NSString *subject = [messagesDeep objectForKey:@"subject"];
		NSString *author = [messagesDeep objectForKey:@"author"];
		NSString *body = [messagesDeep objectForKey:@"body"];
		NSString *date = [[messagesDeep objectForKey:@"created_utc"] description];

		[logger log:[NSString stringWithFormat:@"found an unread with the subject:\"%@\"!", subject]];
		[unreads addObject:[[ORMessage alloc] initWithSubject:subject author:author body:body andDate:date]];
   	}//end for

	[[ORProvider sharedProvider] handleWithMessages:[NSArray arrayWithArray:unreads]];
   	[logger log:@"finished loading and saving! Time to clean up shop and notify."];
   	//[self clean];
}//end fillUnreadDates
/*
-(void)clean{

	[logger log:@"trying to log out..."];
	NSString *logoutString = @"http://www.reddit.com/api/clear_sessions";
	NSURL *logoutURL = [NSURL URLWithString:logoutString];
	NSMutableURLRequest *logoutRequest = [NSMutableURLRequest requestWithURL:logoutURL];
	[logoutRequest setHTTPShouldHandleCookies:YES];
	[logoutRequest setHTTPMethod:@"POST"];

	NSString *logoutRequestString = [NSString stringWithFormat:@"api_type=json&curpass=%@&uh=%@", password, modhash];
	NSData *logoutRequestBody = [logoutRequestString dataUsingEncoding:NSUTF8StringEncoding];
	[logoutRequest setHTTPBody:logoutRequestBody];

	NSOperationQueue *logoutQueue = [[NSOperationQueue alloc] init];
	[NSURLConnection sendAsynchronousRequest:logoutRequest queue:logoutQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		if ([data length] > 0 && error == nil)
			[self performSelectorOnMainThread:@selector(processClearData:) withObject:data waitUntilDone:NO];

		else if ([data length] == 0 && error == nil)
			[self performSelectorOnMainThread:@selector(processClearData:) withObject:[@"Received empty reply." dataUsingEncoding:NSUTF8StringEncoding] waitUntilDone:NO];

		else if (error != nil && error.code == NSURLErrorTimedOut)
			[self performSelectorOnMainThread:@selector(processClearData:) withObject:[@"Timed out." dataUsingEncoding:NSUTF8StringEncoding] waitUntilDone:NO];

		else if (error != nil)
			[self performSelectorOnMainThread:@selector(processClearData:) withObject:[@"Download error." dataUsingEncoding:NSUTF8StringEncoding] waitUntilDone:NO];

		else
			[self performSelectorOnMainThread:@selector(processClearData:) withObject:[@"You broke something!" dataUsingEncoding:NSUTF8StringEncoding] waitUntilDone:NO];
	}];

	[logger log:@"sent logout signal!"];
}//end clear


-(void)processClearData:(NSData *)data {

	NSString *logoutResponseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	[logger log:[NSString stringWithFormat:@"received response (%@) to logout from Reddit, running it through the filter...", logoutResponseString]];

	if([possibleErrors containsObject:logoutResponseString]){
		[logger log:[NSString stringWithFormat:@"hit a problem while processing logout data: %@.", logoutResponseString]];
		[self quitAndHandleError:nil orMessage:logoutResponseString];
		return;
	}

	[logger log:@"all seems well! clearing sessions..."];
	NSError *logoutRequestError = nil;
	NSData *logoutJSONData = [logoutResponseString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *logoutResults = [NSJSONSerialization JSONObjectWithData:logoutJSONData options:0 error:&logoutRequestError];
	if(logoutRequestError){
		[logger log:[NSString stringWithFormat:@"hit a problem parsing (with response string: %@) login information: %@.", logoutResponseString, logoutRequestError]];
		[self quitAndHandleError:nil orMessage:logoutResponseString];
		return;
	}
	
	NSArray *logoutErrorResults = [[logoutResults valueForKey:@"json"] valueForKey:@"errors"];
	if(logoutErrorResults != nil && [logoutErrorResults count] > 0){
		[self quitAndHandleError:nil orMessage:[NSString stringWithFormat:@"%@", logoutErrorResults]];
		return;
	}

	[logger log:@"appears we have successfully logged out!"];
}//end retrieveHash*/

-(void)quitAndHandleError:(NSError *)error orMessage:(NSString *)message{

	[logger log:[NSString stringWithFormat:@"encountered an error. Here's the raw message: %@", message]];
	
	if(![message isEqualToString:@"cancel"]){
		NSString *handleText = @"";

		if(error == nil && message != nil){
			NSArray *parsed = [message componentsSeparatedByString:@"\""];
			int indexToLoad = 0;

			if([parsed count] == 3)
				indexToLoad = 1;
			else if([parsed count] < 3)
				indexToLoad = 0;
			else if ([parsed count] > 3)
				indexToLoad = 3;
			
			NSString *parsedErrorMessage = [parsed objectAtIndex:indexToLoad];
			handleText = ([message rangeOfString:@"404"].location == NSNotFound)?parsedErrorMessage:@"You'll have to respring before switching accounts in this version of Orangered. Sorry!";
		}//end if

		else if(message == nil)
			handleText = @"Received a response we couldn't handle. Try again!";

		handleText = [handleText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if([handleText isEqualToString:@""])
			handleText = @"Couldn't communicate with Reddit. Please check your connection and try again!";

		NSError *error = nil;
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<(.*?)>" options:NSRegularExpressionCaseInsensitive error:&error];
		handleText = [regex stringByReplacingMatchesInString:handleText options:0 range:NSMakeRange(0, [handleText length]) withTemplate:@""];

		NSArray *split = [handleText componentsSeparatedByString:@". "];
		NSString *message, *subtitle;
		if([split count] > 1){
			subtitle = [split objectAtIndex:1];
			message = [split objectAtIndex:0];
		}//end if

		else{
			subtitle = @"try again";
			message = [split objectAtIndex:0];
		}

		NSDictionary *sentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Reddit problem!", @"title", message, @"message", subtitle, @"subtitle", @"fix", @"label", @YES,  @"sound", nil];
		[logger log:@"sent error to become a banner..."];
		[[ORProvider sharedProvider] handleWithDictionary:sentDictionary];
	}//end if
}

-(NSDictionary *)settings{
	return [NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangered.plist"]];
}

-(void)dealloc{
	[logger log:@"all ships have sailed. Closing up shop for Reddit communications, thanks for all the fish."];
}

@end