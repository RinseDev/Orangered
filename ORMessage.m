#import "ORMessage.h"

@implementation ORMessage
@synthesize subject, author, body, date;

-(ORMessage *)initWithSubject:(NSString *)givenSubject author:(NSString *)givenAuthor body:(NSString *)givenBody andDate:(NSString *)givenDate{

	subject = givenSubject;
	author = givenAuthor;
	body = givenBody;
	date = [NSDate dateWithTimeIntervalSince1970:[givenDate doubleValue]];

	return self;
}

-(NSString *)description{
	return [NSString stringWithFormat:@"ORMessage: <subject> %@ <author> %@ <body> %@ <date> %@", subject, author, body, [date description]];
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		subject = [decoder decodeObjectForKey:@"subject"];
		author = [decoder decodeObjectForKey:@"author"];
		body = [decoder decodeObjectForKey:@"body"];
		date = [decoder decodeObjectForKey:@"date"];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:subject forKey:@"subject"];
	[encoder encodeObject:author forKey:@"author"];
	[encoder encodeObject:body forKey:@"body"];
	[encoder encodeObject:date forKey:@"date"];
}

@end