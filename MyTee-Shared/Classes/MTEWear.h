//
//  MTEWear.h
//  mytee
//
//  Created by Vincent Tourraine on 2/2/12.
//  Copyright (c) 2012 Studio AMANgA. All rights reserved.
//

@import Foundation;
@import CoreData;

@class MTETShirt;

@interface MTEWear : NSManagedObject

@property (nonatomic, retain) NSString  *identifier;
@property (nonatomic, retain) NSDate    *date;
@property (nonatomic, retain) MTETShirt *tshirt;

- (id)initInManagedObjectContext:(NSManagedObjectContext *)context;

@end
