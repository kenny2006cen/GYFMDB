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
#import "NSObject+DBRunTimeSave.h"

#import "User.h"
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

@interface GYFMDB(){

    FMDatabase *localDB;
}

@property (strong, nonatomic) FMDatabaseQueue * dbQueue;

@end

@implementation GYFMDB

/*
- (id)initWithDBWithPath:(NSString *)dbPath {
    self = [super init];
    if (self) {
        debugLog(@"dbPath = %@", dbPath);
        if (_dbQueue) {
           
        }
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    }
    return self;
}
*/
-(id)init{
    self = [super init];
    if (self) {
        
        localDB = [FMDatabase databaseWithPath:self.dbPath];
        
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
//IndexsForProperys:(NSArray*)array
        
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
        [localDB close];
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
            
          //   id myobj = [[modelClass alloc] init];
            User *myobj = [[User alloc]init];
            
            for (NSString *key in [dic allKeys]) {
                
                if ([key isEqualToString:@"id"]) {
                   // return ;
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
