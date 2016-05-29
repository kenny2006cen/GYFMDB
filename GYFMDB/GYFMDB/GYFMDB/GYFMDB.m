//
//  GYFMDB.m
//  GYFMDB
//
//  Created by User on 16/5/27.
//  Copyright © 2016年 jlc. All rights reserved.
//

#import "GYFMDB.h"

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "NSObject+GYFMDB.h"

#import <objc/runtime.h>

#ifdef DEBUG
#define debugLog(...)    NSLog(__VA_ARGS__)
#define debugMethod()    NSLog(@"%s", __func__)
#define debugError()     NSLog(@"Error at %s Line:%d", __func__, __LINE__)
#else
#define debugLog(...)
#define debugMethod()
#define debugError()
#endif


#define PATH_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define PATH_CACHE    [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]

@interface GYFMDB()

@end

@implementation GYFMDB

-(id)init{
    self = [super init];
    if (self) {
        
        _localDB = [FMDatabase databaseWithPath:self.dbPath];
        
        [self configDbQueue];
    }
    return self;
}

-(void)configDbQueue{

    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:self.dbPath];
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static GYFMDB *_singleton = nil;
   
    dispatch_once(&onceToken,^{
        _singleton = [[GYFMDB alloc]init];
        
    });
    return _singleton;
}

-(NSString*)dbPath{

    NSString * dbPath = [PATH_DOCUMENT stringByAppendingPathComponent:@"data.db"];

     debugLog(@"dbPath = %@", dbPath);
    return  dbPath;
    
}

-(BOOL)createTableWithName:(NSString *)tableName ColumnNameFromModel:(id)model{
        
    NSArray *attributes = [model attributePropertyList];
    
    NSMutableString *mutSql = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (",tableName];
    
    [mutSql appendFormat:@"id INTEGER PRIMARY KEY AUTOINCREMENT,"];
    
    for (int i=0; i<attributes.count; i++) {
        
         NSString *key = attributes[i];
        
        if (i!=attributes.count-1) {
            [mutSql appendFormat:@"'%@' TEXT, ", key];

        }
        else{
             [mutSql appendFormat:@"'%@' TEXT)", key];
        }
        
    }
    
    __block BOOL flag =NO;
    
    [[GYFMDB sharedInstance].dbQueue inDatabase:^(FMDatabase *db) {
       
       flag = [db executeUpdate:mutSql];
        
    }];
    
    if (flag) {
        NSLog(@"建表成功:%@",tableName);
        [_localDB close];
    }
    return flag;
    
}

-(BOOL)insertModel:(id)model ToTable:(NSString*)tableName{

    NSArray *attributes = [model attributePropertyList];
    
    NSMutableString *keyString =[NSMutableString new];
    NSMutableString *valueString = [NSMutableString new];
    
    for (int i=0; i<attributes.count; i++) {
        
        NSString *key = attributes[i];
        
        //获取对应属性的值
        id value = [model valueForKey:key];
        
        if(value == nil||[value isKindOfClass:[NSNull class]])
        {
            value = @"''";
        }
        
        if (i!=attributes.count-1) {
            [keyString appendFormat:@"%@,",key];
            [valueString appendFormat:@"'%@',",value];
            
        }
        else{
            [keyString appendFormat:@"%@",key];
            [valueString appendFormat:@"'%@'",value];

        }
        
    }
    
    NSMutableString *mutSql = [NSMutableString stringWithFormat:@"INSERT INTO '%@' (%@) VALUES (%@)",tableName,keyString,valueString];
    
    __block BOOL flag = NO;
    
    [[GYFMDB sharedInstance].dbQueue inDatabase:^(FMDatabase *db) {
       
        NSError *error=nil;
        
       flag  = [db executeUpdate:mutSql withErrorAndBindings:&error];
        
        if (flag) {
            NSLog(@"插入成功");
            
          //  [self.dbQueue close];
        }
    }];
    
    return flag;
}

// 根据属性删除字段
-(BOOL)deleteModel:(id)model FromTable:(NSString*)tableName ByCondition:(NSString*)propertyName EqualsTo:(NSString*)value{

    __block BOOL flag =NO;

     NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM '%@' WHERE %@ = '%@'",tableName,propertyName,value];
    
    [[GYFMDB sharedInstance].dbQueue inDatabase:^(FMDatabase *db) {
     
        NSError *error =nil;
        
       flag = [db executeQuery:deleteSql values:@[] error:&error];
        
        if (flag) {
            NSLog(@"删除成功");
        }
    }];
    return flag;
}

-(BOOL)deleteAllFromTable:(NSString*)tableName{
    
    __block BOOL flag =NO;
    
    NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM '%@'",tableName];

    [[GYFMDB sharedInstance].dbQueue inDatabase:^(FMDatabase *db) {
        
        NSError *error =nil;
        
        flag = [db executeQuery:deleteSql values:@[] error:&error];
    }];
    
    return flag;
}

-(BOOL)updateModel:(id)model FromTable:(NSString*)tableName ByCondition:(NSString*)propertyName EqualsTo:(NSString*)value{

    __block BOOL flag =NO;

    NSArray *attributes = [model attributePropertyList];
    
    
    NSMutableString *keyString =[NSMutableString new];
    NSMutableString *valueString = [NSMutableString new];
    
    for (int i=0; i<attributes.count; i++) {
        
        NSString *key = attributes[i];
        
        //获取对应属性的值
        id value = [model valueForKey:key];
        
        if(value == nil||[value isKindOfClass:[NSNull class]])
        {
           // value = @"''";
        }
        else{
            //有值的时候才更新
            if (i!=attributes.count-1) {
                [keyString appendFormat:@"%@,",key];
                [valueString appendFormat:@"'%@',",value];
                
            }
            else{
                [keyString appendFormat:@"%@",key];
                [valueString appendFormat:@"'%@'",value];
                
            }
//            if (i!=attributes.count-1) {
//                [keyString appendFormat:@"%@=?,",key];
//                [valueString appendFormat:@"'%@',",value];
//                
//            }
//            else{
//                [keyString appendFormat:@"%@=?",key];
//                [valueString appendFormat:@"'%@'",value];
//                
//            }
        }
        
        
    }
//sqlite> UPDATE COMPANY SET ADDRESS = 'Texas', SALARY = 20000.00
//     NSString *updateSql = [NSString stringWithFormat:@"UPDATE '%@' SET %@  WHERE %@='%@'",tableName,keyString,propertyName,value];
     NSString *updateSql = [NSString stringWithFormat:@"UPDATE User SET userName = 'kenny2006' WHERE userName = 'jack222'"];
//     NSString *updateSql = [NSString stringWithFormat:@"REPLACE INTO '%@' (%@) VALUES('%@')",tableName,propertyName,value];
    
    [[GYFMDB sharedInstance].dbQueue inDatabase:^(FMDatabase *db) {
        
        NSError *error =nil;
        
        flag = [db executeUpdate:updateSql withErrorAndBindings:&error];
        
        if (flag) {
            NSLog(@"更新成功");
        }
    }];
    
    return flag;
}

-(NSArray*)queryModels:(Class)modelClass FromTable:(NSString*)tableName{
    
    __block NSMutableArray *selectArray = [NSMutableArray array];

    
    NSMutableString *muteSql =[NSMutableString stringWithFormat:@"SELECT * FROM %@",tableName];
    
    //注册这个类到runtime系统中就可以使用
    
//    NSObject * myobj = [[modelClass alloc] init];
    
    [[GYFMDB sharedInstance].dbQueue inDatabase:^(FMDatabase *db) {
       
        NSError *error;
        
        FMResultSet *resultSet = [db executeQuery:muteSql values:@[] error:&error];
        
        while (resultSet.next) {
            
            NSDictionary *dic = [resultSet resultDictionary];
            
             id myobj = [[modelClass alloc] init];
          //  User *myobj = [[User alloc]init];
            
            for (NSString *key in [dic allKeys]) {
                
                if ([key isEqualToString:@"id"]) {
                   // return ;
                    //不存储主键
                }
                else{
                    id value = dic[key];
                //增加属性
           //     objc_setAssociatedObject(myobj, [key UTF8String], value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                
                    if (value ==nil||[value isKindOfClass:[NSNull class]]) {
                    value =@"";
                    }
                    
                    [myobj setValue:value forKey:key];
                
                }
                
                [selectArray addObject:myobj];

            }
            
        }
    }];
    
    [self.dbQueue close];;
    
    return selectArray;
}

- (void)close {
    [_dbQueue close];
    _dbQueue = nil;
}

@end
