//
//  GYFMDB.h
//  GYFMDB
//
//  Created by User on 16/5/27.
//  Copyright © 2016年 jlc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GYKeyValueItem : NSObject

@property (strong, nonatomic) NSString *key;
@property (strong, nonatomic) id object;
@property (strong, nonatomic) NSDate *createdTime;


@end

@interface GYFMDB : NSObject

-(instancetype)sharedDB;

- (id)initWithDBWithPath:(NSString *)dbPath;

- (void)createTableWithName:(NSString *)tableName;

- (BOOL)isTableExists:(NSString *)tableName;

- (BOOL)clearTable:(NSString *)tableName;

/*** 以下为用keyValue形式存储数据库方法****/

- (BOOL)saveObject:(id)object withKey:(NSString *)objectKey intoTable:(NSString *)tableName;

- (id)getObjectByKey:(NSString *)objectKey fromTable:(NSString *)tableName;

- (GYKeyValueItem *)getKeyValueItemByKey:(NSString *)objectKey fromTable:(NSString *)tableName;

- (NSArray *)getAllKeyValueItemsFromTable:(NSString *)tableName;

- (NSUInteger)getCountFromTable:(NSString *)tableName;

- (BOOL)deleteObjectByKey:(NSString *)objectKey fromTable:(NSString *)tableName;

- (BOOL)deleteObjectsByKeyArray:(NSArray *)objectKeyArray fromTable:(NSString *)tableName;

/***********************************/



@end
