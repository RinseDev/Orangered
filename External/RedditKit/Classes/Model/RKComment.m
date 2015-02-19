// RKComment.m
//
// Copyright (c) 2014 Sam Symons (http://samsymons.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "RKComment.h"
#import "RKObjectBuilder.h"
#import "RKClient.h"

@implementation RKComment

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSDictionary *keyPaths = @{
        @"approvedBy": @"data.approved_by",
        @"bannedBy": @"data.banned_by",
        @"author": @"data.author",
        @"linkAuthor": @"data.link_author",
        @"body": @"data.body",
        @"bodyHTML": @"data.body_html",
        @"scoreHidden": @"data.score_hidden",
        @"replies": @"data.replies",
        @"edited": @"data.edited",
        @"archived": @"data.archived",
        @"saved": @"data.saved",
        @"linkID": @"data.link_id",
        @"gilded": @"data.gilded",
        @"score": @"data.score",
        @"controversiality": @"controversiality",
        @"parentID": @"data.parent_id",
        @"subreddit": @"data.subreddit",
        @"subredditID": @"data.subreddit_id"
        //		@"totalReports": @"data.num_reports",          // not required for now.
        //		@"distinguishedStatus": @"data.distinguished", // not required for now.
    };
    
    return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:keyPaths];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, author: %@, parentID: %@, fullName: %@, replies: %lu>", NSStringFromClass([self class]), self, self.author, self.parentID, self.fullName, (unsigned long)self.replies.count];
}

- (BOOL)isDeleted
{
    return [[self author] isEqualToString:@"[deleted]"] && [[self body] isEqualToString:@"[deleted]"];
}

#pragma mark - MTLModel

+ (NSValueTransformer *)repliesJSONTransformer
{
    return [MTLValueTransformer transformerWithBlock:^id(id replies) {
        if ([replies isKindOfClass:[NSString class]])
        {
            return @[];
        }
        
        NSArray *repliesData = [replies valueForKeyPath:@"data.children"];
        NSMutableArray *comments = [[NSMutableArray alloc] initWithCapacity:repliesData.count];
        
        for (NSDictionary *commentJSON in repliesData)
        {   
            NSError *error = nil;
            id model = [RKObjectBuilder objectFromJSON:commentJSON];
            
            if (!error)
            {
                [comments addObject:model];
            }
        }
        
        return [comments copy];
    }];
}

+ (NSValueTransformer *)editedJSONTransformer
{
    return [MTLValueTransformer transformerWithBlock:^id(NSNumber *created) {
        if (![created boolValue])
        {
            return nil;
        }
        else
        {
            NSTimeInterval createdTimeInterval = [created unsignedIntegerValue];
            return [NSDate dateWithTimeIntervalSince1970:createdTimeInterval];
        }
    }];
}

@end
