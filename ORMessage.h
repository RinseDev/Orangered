@interface ORMessage : NSObject <NSCoding>

@property (retain, nonatomic) NSString *subject;
@property (retain, nonatomic) NSString *author;
@property (retain, nonatomic) NSString *body;
@property (retain, nonatomic) NSDate *date;

-(ORMessage *)initWithSubject:(NSString *)givenSubject author:(NSString *)givenAuthor body:(NSString *)givenBody andDate:(NSString *)date;
-(NSString *)description;

@end