//
//  NSObject+DBRunTimeSave.m
//  GYFMDB
//
//  Created by User on 16/5/28.
//  Copyright © 2016年 jlc. All rights reserved.
//

#import "NSObject+DBRunTimeSave.h"
#import <objc/runtime.h>

@implementation NSObject (DBRunTimeSave)

-(NSMutableDictionary *)attributeProrertyDic{
    unsigned int count = 0;
  
    Ivar *ivars = class_copyIvarList([self class], &count);
    
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (int i = 0; i<count; i++) {
        
        // 取出i位置对应的成员变量
        Ivar ivar = ivars[i];
        
        // 查看成员变量
        const char *name = ivar_getName(ivar);
       
       const char *type = ivar_getTypeEncoding(ivar);
                // 归档
        NSString *key = [NSString stringWithUTF8String:name];
        
        NSLog(@"属性名称:%s ,属性类型名称:%s",name,type);

        //type字段:nsinter ,long long属性,返回类型q,bool 类型返回B ，其他返回正常字符串如NSNumber,NSDate
        id value = [self valueForKey:key];
      
        if ([value isKindOfClass:[NSNull class]] || value == nil) {
          //  value = @"";
            value = [NSString stringWithUTF8String:type];
        }
        NSString *realKey = [key substringFromIndex:1];
        
        [dic setObject:value forKey:realKey];
    }
    
    free(ivars);
    
//    // 属性操作
//    unsigned  outCount =0;
//    objc_property_t * properties = class_copyPropertyList([self class], &outCount);
//    for (int i = 0; i < outCount; i++) {
//        objc_property_t property = properties[i];
//   
//        NSLog(@"property's name: %s", property_getName(property));
// 
//    }
//    
//    free(properties);
    
    return dic;
}

/**
 *  返回属性列表 数组
 *
 *  @return @[@"userId",@"userName"]
 */
-(NSArray *)attributePropertyList{
    
    NSDictionary *dic = [self attributeProrertyDic];
    NSArray *array = [dic allKeys];
    return array;
}
/**
 *
 *
 *  @return 返回属性字典
    @{@"userName":@"NSString"}
 */

-(NSDictionary*)attributePropertyDic{

    NSDictionary *dic = [self attributeProrertyDic];
    
    return dic;
}



@end
