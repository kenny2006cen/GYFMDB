//
//  GYFMDB.h
//  GYFMDB
//
//  Created by User on 16/5/27.
//  Copyright © 2016年 jlc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabaseAdditions.h>

typedef void (^QueryFinishBlock) (FMResultSet *set);

@interface GYKeyValueItem : NSObject

@property (strong, nonatomic) NSString *key;
@property (strong, nonatomic) id object;
@property (strong, nonatomic) NSDate *createdTime;


@end

@interface GYFMDB : NSObject

@property (strong, nonatomic) FMDatabaseQueue * dbQueue;
@property (strong, nonatomic) FMDatabase *localDB;


- (id)initWithDBWithPath:(NSString *)dbPath;

- (void)createTableWithName:(NSString *)tableName;

- (BOOL)isTableExists:(NSString *)tableName;

- (BOOL)clearTable:(NSString *)tableName;

- (NSInteger)getCountFromTable:(NSString *)tableName;

- (BOOL)deleteObjectByKey:(NSString *)objectKey fromTable:(NSString *)tableName;

- (BOOL)deleteObjectsByKeyArray:(NSArray *)objectKeyArray fromTable:(NSString *)tableName;

/***********************************/
+ (instancetype)sharedInstance;

//根据模型生成表以及表结构
-(BOOL)createTableWithName:(NSString *)tableName ColumnNameFromModel:(id)model;

//-(BOOL)deleteTableWithName:(NSString *)tableName;

-(BOOL)insertModel:(id)model ToTable:(NSString*)tableName;

-(BOOL)deleteModel:(id)model FromTable:(NSString*)tableName ByCondition:(NSString*)propertyName EqualsTo:(NSString*)value;

-(BOOL)updateModel:(id)model FromTable:(NSString*)tableName ByCondition:(NSString*)propertyName EqualsTo:(NSString*)value;

-(NSArray*)queryModels:(Class)modelClass FromTable:(NSString*)tableName;

@end
