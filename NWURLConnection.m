#import "NWURLConnection.h"

@implementation NWURLConnection {
    NSURLConnection *connection;
    NSHTTPURLResponse *response;
    NSMutableData *responseData;
}

@synthesize request, queue, completionHandler;

+ (NWURLConnection *)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void(^)(NSURLResponse *response, NSData *data, NSError *error))completionHandler
{
    NWURLConnection *result = [[NWURLConnection alloc] init];
    result.request = request;
    result.queue = queue;
    result.completionHandler = completionHandler;
    [result start];
    return result;
}

- (void)dealloc
{
    [self cancel];
}

- (void)start
{
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [connection scheduleInRunLoop:NSRunLoop.mainRunLoop forMode:NSDefaultRunLoopMode];
    if (connection) {
        [connection start];
    } else {
        if (completionHandler) completionHandler(nil, nil, nil); completionHandler = nil;
    }
}

- (void)cancel
{
    [connection cancel]; connection = nil;
    completionHandler = nil;
}

- (void)connection:(NSURLConnection *)_connection didReceiveResponse:(NSHTTPURLResponse *)_response
{
    response = _response;
}

- (void)connection:(NSURLConnection *)_connection didReceiveData:(NSData *)data
{
    if (!responseData) {
        responseData = [NSMutableData dataWithData:data];
    } else {
        [responseData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)_connection
{
    connection = nil;
    if (completionHandler) {
        void(^b)(NSURLResponse *response, NSData *data, NSError *error) = completionHandler;
        completionHandler = nil;
        [queue addOperationWithBlock:^{b(response, responseData, nil);}];
    }
}

- (void)connection:(NSURLConnection *)_connection didFailWithError:(NSError *)error
{
    connection = nil;
    if (completionHandler) {
        void(^b)(NSURLResponse *response, NSData *data, NSError *error) = completionHandler;
        completionHandler = nil;
        [queue addOperationWithBlock:^{b(response, responseData, error);}];
    }
}

#if TARGET_IPHONE_SIMULATOR
- (BOOL)connection:(NSURLConnection *)_connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}
- (void)connection:(NSURLConnection *)_connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}
#endif

@end
