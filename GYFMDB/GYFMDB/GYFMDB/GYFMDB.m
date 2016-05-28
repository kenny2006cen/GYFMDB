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
    
    return flag;
    
}

- (void)close {
    [_dbQueue close];
    _dbQueue = nil;
}

@end
