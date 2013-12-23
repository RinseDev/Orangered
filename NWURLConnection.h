// NWURLConnection - an NSURLConnectionDelegate based on blocks with cancel.
// Similar to the `sendAsynchronousRequest:` method of NSURLConnection, but
// with `cancel` method. Requires ARC on iOS 6 or Mac OS X 10.8.
// License: BSD
// Author:  Leonard van Driel, 2012

@interface NWURLConnection : NSObject <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, copy) void(^completionHandler)(NSURLResponse *response, NSData *data, NSError *error);

+ (NWURLConnection *)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void(^)(NSURLResponse *response, NSData *data, NSError *error))completionHandler;
- (void)start;
- (void)cancel;

@end