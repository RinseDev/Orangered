
@interface SBBulletinBannerController {
	NSMutableArray* _bulletinQueue;
	BBObserver* _observer;
	NSMutableSet* _sectionIDsToPend;
}

+(id)sharedInstanceIfExists;
+(id)sharedInstance;
+(id)_sharedInstanceCreateIfNecessary:(BOOL)necessary;
-(id)observer:(id)observer composedAttachmentImageForType:(int)type thumbnailData:(id)data key:(id)key;
-(id)observer:(id)observer thumbnailSizeConstraintsForAttachmentType:(int)attachmentType;
-(BOOL)observerShouldFetchAttachmentImageBeforeBulletinDelivery:(id)observer;
-(void)observer:(id)observer updateSectionInfo:(id)info;
-(void)observer:(id)observer removeBulletin:(id)bulletin;
-(void)observer:(id)observer modifyBulletin:(id)bulletin;
-(void)observer:(id)observer addBulletin:(id)bulletin forFeed:(unsigned)feed;
-(void)removeAllBannerItems;
-(id)dequeueNextBannerItem;
-(id)peekNextBannerItem;
-(id)newBannerViewForItem:(id)item;
-(void)_removeNextBulletinIfNecessary;
-(void)_queueBulletin:(id)bulletin;
-(BOOL)_replaceBulletin:(id)bulletin;
-(void)_removeBulletin:(id)bulletin;
-(unsigned)_indexOfQueuedBulletinID:(id)queuedBulletinID;
-(void)_configureBBObserver;
-(void)showTestBanner;
-(void)dealloc;
-(id)init;
@end