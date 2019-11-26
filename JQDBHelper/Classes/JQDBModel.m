//
//  JQDBModel.m
//  JQDBHelper
//
//  Created by zhangjinquan on 2019/11/26.
//

#import "JQDBModel.h"
#import <YYModel/YYModel.h>

@implementation NSObject (JQDBModel)

+ (NSArray *)jqdb_allColumes {
    if ([self respondsToSelector:@selector(jqdb_columeDefines)]) {
        return [[(id<JQDBModel>)self jqdb_columeDefines] allKeys];
    }
    NSMutableSet *propsSet = [NSMutableSet set];
    YYClassInfo *classInfo = [YYClassInfo classInfoWithClass:self];
    while (classInfo) {
        [propsSet addObjectsFromArray:[classInfo.propertyInfos allKeys]];
        classInfo = classInfo.superClassInfo;
    }
    return [propsSet allObjects];
}

- (NSDictionary *)jqdb_modelToDictionary {
    NSArray *columes = [[self class] jqdb_allColumes];
    NSDictionary *origin = [self yy_modelToJSONObject];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[columes count]];
    NSSet *embedBlobSet = nil;
    NSSet *embedJsonSet = nil;
    if ([[self class] respondsToSelector:@selector(jqdb_columesEmbededAsBlob)]) {
        embedBlobSet = [NSSet setWithArray:[[self class] jqdb_columesEmbededAsBlob]];
    }
    if ([[self class] respondsToSelector:@selector(jqdb_columesEmbededAsJson)]) {
        embedJsonSet = [NSSet setWithArray:[[[self class] jqdb_columesEmbededAsJson] allKeys]];
    }
    
    for (NSString *col in columes) {
        id value = origin[col];
        if (value) {
            if ([embedBlobSet containsObject:col]) {
                value = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
            } else if ([embedJsonSet containsObject:col]) {
                value = [value yy_modelToJSONString];
            }
            [dict setObject:value forKey:col];
        }
        else {
            [dict setObject:[NSNull null] forKey:col];
        }
    }
    return dict;
}

- (NSData *)blobData {
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self yy_modelToJSONObject] options:0 error:nil];
    if (data) {
        return  data;
    } else {
        return [[NSData alloc] init];
    }
}

+ (instancetype)jqdb_modelWithDictionary:(NSDictionary *)dictionary {
    if ([[self class] respondsToSelector:@selector(jqdb_columesEmbededAsBlob)]) {
        NSArray *arr = [[self class] jqdb_columesEmbededAsBlob];
        if ([arr count]) {
            NSMutableDictionary *mdict = [dictionary mutableCopy];
            for (NSString *col in arr) {
                NSData *data = [mdict objectForKey:col];
                if (data) {
                    id value = nil;
                    if ([data isKindOfClass:[NSData class]]) {
                        value = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    }
                    if (value) {
                        [mdict setObject:value forKey:col];
                    }
                    else {
                        [mdict removeObjectForKey:col];
                    }
                }
            }
            dictionary = mdict;
        }
    } else if ([[self class] respondsToSelector:@selector(jqdb_columesEmbededAsJson)]) {
        NSDictionary *classDic = [[self class] jqdb_columesEmbededAsJson];
        if ([classDic count]) {
            NSMutableDictionary *mdict = [dictionary mutableCopy];
            for (NSString *col in [classDic allKeys]) {
                NSString *json = [mdict objectForKey:col];
                if (json) {
                    id value = nil;
                    if ([json isKindOfClass:[NSString class]]) {
                        Class clz = [classDic objectForKey:col];
                        value = [clz yy_modelWithJSON:json];
                    }
                    if (value) {
                        [mdict setObject:value forKey:col];
                    }
                    else {
                        [mdict removeObjectForKey:col];
                    }
                }
            }
            dictionary = mdict;
        }
    }
    
    return [self yy_modelWithDictionary:dictionary];
}

@end

@implementation NSArray (JQDBModel)

- (NSArray *)jqdb_modelToDictionarys {
    NSMutableArray *paramsList = [NSMutableArray array];
    for (id obj in self) {
        NSDictionary *dict = nil;
        if ([obj isKindOfClass:[NSDictionary class]]) {
            dict = obj;
        } else {
            dict = [obj jqdb_modelToDictionary];
        }
        if (dict) {
            [paramsList addObject:dict];
        }
    }
    return paramsList;
}

- (NSArray *)jqdb_dictionaryToModelsOfClass:(Class)modelClass {
    NSMutableArray *objects = [NSMutableArray array];
    for (id dict in self) {
        id obj = [modelClass jqdb_modelWithDictionary:dict];
        if (obj) {
            [objects addObject:obj];
        }
    }
    return objects;
}

@end
