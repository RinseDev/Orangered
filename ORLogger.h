@interface ORLogger : NSObject {
	NSString *source;
}

@property (nonatomic, retain) UIView *debugView;
@property (nonatomic, retain) UITextView *debugTextView;


+(BOOL)log:(NSString *)string fromSource:(NSString *)string2;
-(ORLogger *)initFromSource:(NSString *)string;
-(void)log:(NSString *)string;
-(UIView *)createView;
-(void)removeView;
@end

@interface NSString (Orangered)
-(BOOL)isEmpty;
@end