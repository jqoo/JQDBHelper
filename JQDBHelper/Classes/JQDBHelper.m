//
//  JQDBHelper.m
//  JQDBHelper
//
//  Created by zhangjinquan on 2019/11/26.
//

#import "JQDBHelper.h"

NSString * const jqdb_TEXT = @"TEXT";
NSString * const jqdb_INTEGER = @"INTEGER";
NSString * const  jqdb_REAL = @"REAL";
NSString * const jqdb_BIGINT = @"BIGINT";
NSString * const jqdb_BOOL = @"INTEGER";
NSString * const jqdb_BLOB = @"BLOB";

NSString * const jqdb_PRIMARY_KEY = @"PRIMARY KEY";
NSString * const jqdb_NOT_NULL = @"NOT NULL";
NSString * const jqdb_UNIQUE = @"UNIQUE";

NSString * jqdb_DEFAULT(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"DEFAULT %@", value];
    }
    return [NSString stringWithFormat:@"DEFAULT \"%@\"", value];
}

NSString * jqdb_CHECK(NSString *check) {
    return [NSString stringWithFormat:@"CHECK (%@)", check];
}

#define lcsql_setValue(name, val) \
do { \
    __strong typeof(weakSelf) strongSelf = weakSelf; \
    if (strongSelf) { \
        strongSelf->name = val; \
    } \
} while(0)

#define lcsql_initBlock(blk) \
blk = [^(id value) { \
    lcsql_setValue(_v##blk, value); \
    return weakSelf; \
} copy]

static NSString *priv_defineColume(NSString *col, id def) {
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:col];
    
    if ([def isKindOfClass:[NSString class]]) {
        [arr addObject:def];
    }
    else if ([def isKindOfClass:[NSArray class]]) {
        [arr addObjectsFromArray:def];
    }
    return [arr componentsJoinedByString:@" "];
}

typedef enum {
    JQDBSqlModify_Insert,
    JQDBSqlModify_Replace,
    JQDBSqlModify_Update
} JQDBSqlModify_Type;

@implementation JQDBSql
{
@package
    NSString *_v_where;
    NSString *_v_schema;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        __weak typeof(self) weakSelf = self;
        
        lcsql_initBlock(_where);
        lcsql_initBlock(_schema);
        
        _build = [^{
            return [weakSelf doBuild];
        } copy];
    }
    return self;
}

- (instancetype)initWithModifyType:(JQDBSqlModify_Type)modifyType {
    return nil;
}

- (NSString *)doBuild {
    return nil;
}

+ (JQDBSqlSelect *)select {
    return [[JQDBSqlSelect alloc] init];
}

+ (JQDBSqlDelete *)del {
    return [[JQDBSqlDelete alloc] init];
}

+ (JQDBSqlModify *)insert {
    return [[JQDBSqlModify alloc] initWithModifyType:JQDBSqlModify_Insert];
}

+ (JQDBSqlModify *)replace {
    return [[JQDBSqlModify alloc] initWithModifyType:JQDBSqlModify_Replace];
}

+ (JQDBSqlModify *)update {
    return [[JQDBSqlModify alloc] initWithModifyType:JQDBSqlModify_Update];
}

+ (JQDBSqlSelect *)selectModel:(Class)modelClass columes:(NSArray *)columes {
    return [self select].columes(columes).from(@[[modelClass jqdb_tableName]]);
}

+ (JQDBSqlDelete *)delModel:(Class)modelClass {
    return [self del].from([modelClass jqdb_tableName]);
}

+ (JQDBSqlModify *)insertModel:(Class)modelClass {
    return [self insert].table([modelClass jqdb_tableName]).columes([modelClass jqdb_allColumes]);
}

+ (JQDBSqlModify *)replaceModel:(Class)modelClass {
    return [self replace].table([modelClass jqdb_tableName]).columes([modelClass jqdb_allColumes]);
}

+ (JQDBSqlModify *)updateModel:(Class)modelClass columes:(NSArray *)columes {
    return [self update].table([modelClass jqdb_tableName]).columes(columes);
}

+ (NSString *)sql_createTableOfModel:(Class)modelClass onSchema:(NSString *)schema {
    NSString *tableName = [modelClass jqdb_tableName];
    if (schema) {
        tableName = [schema stringByAppendingFormat:@".%@", tableName];
    }
    
    NSDictionary *columeDefines = [modelClass jqdb_columeDefines];
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:[columeDefines count]];
    
    [columeDefines enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull col, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [lines addObject:priv_defineColume(col, obj)];
    }];
    NSArray *pks = nil;
    if ([modelClass respondsToSelector:@selector(jqdb_tablePrimaryKeys)]) {
        pks = [modelClass jqdb_tablePrimaryKeys];
    }
    if ([pks count]) {
        [lines addObject:[NSString stringWithFormat:@"PRIMARY KEY (%@)", [pks componentsJoinedByString:@","]]];
    }
    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", tableName, [lines componentsJoinedByString:@","]];
}

+ (NSString *)sql_createIndexOfModel:(Class)modelClass onSchema:(NSString *)schema {
    NSArray *keys = nil;
    if ([modelClass respondsToSelector:@selector(jqdb_indexKeys)]) {
        keys = [modelClass jqdb_indexKeys];
    }
    if ([keys count]) {
        NSString *tableName = [modelClass jqdb_tableName];
        NSString *indexName = [NSString stringWithFormat:@"idx_%@", tableName];
        if (schema) {
            tableName = [schema stringByAppendingFormat:@".%@", tableName];
            indexName = [schema stringByAppendingFormat:@".%@", indexName];
        }
        return [NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS idx_%@ ON %@ (%@)", indexName, tableName, [keys componentsJoinedByString:@","]];
    }
    return nil;
}

@end

@implementation JQDBSqlDelete
{
@package
    NSString *_v_from;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        __weak typeof(self) weakSelf = self;
        
        lcsql_initBlock(_from);
    }
    return self;
}

- (NSString *)doBuild {
    NSString *tableName = _v_from;
    if (_v_schema) {
        tableName = [_v_schema stringByAppendingFormat:@".%@", tableName];
    }
    NSMutableString *msql = [NSMutableString stringWithFormat:@"DELETE FROM %@ ", tableName];
    if ([_v_where length]) {
        [msql appendFormat:@"WHERE %@", _v_where];
    }
    return msql;
}

@end

@implementation JQDBSqlSelect
{
    NSArray *_v_columes;
    NSArray *_v_from;
    NSArray *_v_groupby;
    NSArray *_v_orderby;
    NSNumber *_v_limit_offset;
    NSNumber *_v_limit_count;
    NSString *_v_direction;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        __weak typeof(self) weakSelf = self;
        
        lcsql_initBlock(_columes);
        lcsql_initBlock(_from);
        lcsql_initBlock(_groupby);
        lcsql_initBlock(_orderby);
//        lcsql_initBlock(_direction);
        
        _limit = [^(int offset, int count) {
            lcsql_setValue(_v_limit_offset, @(offset));
            if (count > 0) {
                lcsql_setValue(_v_limit_count, @(count));
            }
            return weakSelf;
        } copy];
    }
    return self;
}

- (NSString *)doBuild {
    NSMutableString *msql = [NSMutableString stringWithFormat:@"SELECT %@ ",
                             [_v_columes count] ? [_v_columes componentsJoinedByString:@","] : @"*"];
    if ([_v_from count]) {
        NSMutableArray *tables = [NSMutableArray array];
        for (NSString *table in _v_from) {
            if (_v_schema && [table rangeOfString:@"."].location == NSNotFound) {
                [tables addObject:[NSString stringWithFormat:@"%@.%@", _v_schema, table]];
            }
            else {
                [tables addObject:table];
            }
        }
        [msql appendFormat:@"FROM %@ ", [tables componentsJoinedByString:@","]];
    }
    if ([_v_where length]) {
        [msql appendFormat:@"WHERE %@", _v_where];
    }
    if ([_v_groupby count]) {
        [msql appendFormat:@"GROUPBY %@ ", [_v_groupby componentsJoinedByString:@","]];
    }
    if ([_v_orderby count]) {
        [msql appendString:@" ORDER  BY "];
        [_v_orderby enumerateObjectsUsingBlock:^(NSDictionary *order, NSUInteger idx, BOOL * _Nonnull stop) {
            [msql appendFormat:@" %@ %@ ",[order.allKeys lastObject],[[order allValues] lastObject]];
            if (idx < _v_orderby.count -1) {
                [msql appendString:@", "];
            }
        }];
    }
    if (_v_limit_offset) {
        if (_v_limit_count) {
            [msql appendFormat:@"LIMIT %d, %d ", [_v_limit_offset intValue], [_v_limit_count intValue]];
        }
        else {
            [msql appendFormat:@"LIMIT %d ", [_v_limit_offset intValue]];
        }
    }
    return msql;
}

@end

@implementation JQDBSqlModify
{
    NSString *_v_table;
    NSArray *_v_columes;
    BOOL _v_placeholder;
    JQDBSqlModify_Type _modifyType;
}

- (instancetype)initWithModifyType:(JQDBSqlModify_Type)modifyType {
    self = [super init];
    if (self) {
        _modifyType = modifyType;
        
        __weak typeof(self) weakSelf = self;
        
        lcsql_initBlock(_table);
        lcsql_initBlock(_columes);
        lcsql_initBlock(_placeholder);
    }
    return self;
}

- (NSString *)doBuild {
    NSMutableString *msql = [NSMutableString string];
    NSString *table = _v_table;
    if (_v_schema && [_v_table rangeOfString:@"."].location == NSNotFound) {
        table = [NSString stringWithFormat:@"%@.%@", _v_schema, table];
    }
    if (_modifyType == JQDBSqlModify_Update) {
        [msql appendFormat:@"UPDATE %@ ", table];
        
        if ([_v_columes count]) {
            NSInteger i = 0;
            [msql appendFormat:@"SET %@=%@ ", _v_columes[i], [self valueTextAtIndex:i]];
            for (++i; i < [_v_columes count]; i++) {
                [msql appendFormat:@",%@=%@ ", _v_columes[i], [self valueTextAtIndex:i]];
            }
        }
        if ([_v_where length] > 0) {
            [msql appendFormat:@"WHERE %@", _v_where];
        }
    }
    else {
        [msql appendFormat:@"%@ INTO %@ (%@) ",
         _modifyType == JQDBSqlModify_Replace ? @"REPLACE":@"INSERT",
         table, [_v_columes componentsJoinedByString:@","]
         ];
        if ([_v_columes count]) {
            NSInteger i = 0;
            [msql appendFormat:@"VALUES (%@", [self valueTextAtIndex:i]];
            for (++i; i < [_v_columes count]; i++) {
                [msql appendFormat:@",%@", [self valueTextAtIndex:i]];
            }
            [msql appendString:@") "];
        }
    }
    return msql;
}

- (NSString *)valueTextAtIndex:(NSInteger)index {
    return _v_placeholder ? @"?":[@":" stringByAppendingString:_v_columes[index]];
}

@end

@implementation FMResultSet (JQDBHelper)

- (NSArray *)jqdb_toArray {
    NSMutableArray *results = [NSMutableArray array];
    while ([self next]) {
        [results addObject:[self resultDictionary]];
    }
    [self close];
    return results;
}

- (NSDictionary *)jqdb_any {
    NSDictionary *one = nil;
    if ([self next]) {
        one = [self resultDictionary];
    }
    [self close];
    return one;
}

- (void)jqdb_enumerate:(void (^)(NSDictionary *dict, BOOL *stop))blk {
    if (!blk) {
        return;
    }
    [self jqdb_run:^(FMResultSet *me, BOOL *stop) {
        blk([me resultDictionary], stop);
    }];
}

- (void)jqdb_run:(void (^)(FMResultSet *me, BOOL *stop))blk {
    if (!blk) {
        return;
    }
    BOOL stop = NO;
    while (!stop && [self next]) {
        blk(self, &stop);
    }
    [self close];
}

- (NSArray *)jqdb_toArrayOfModel:(Class)modelClass {
    if ([modelClass conformsToProtocol:@protocol(JQDBModel)]) {
        NSMutableArray *results = [NSMutableArray array];
        [self jqdb_enumerate:^(NSDictionary *dict, BOOL *stop) {
            id obj = [modelClass jqdb_modelWithDictionary:dict];
            if (obj) {
                [results addObject:obj];
            }
        }];
        return results;
    }
    return nil;
}

@end

@implementation JQDBHelper
{
    FMDatabase *_db;
    NSString *_schema;
}

- (instancetype)initWithDB:(FMDatabase *)db schema:(NSString *)schema {
    self = [super init];
    if (self) {
        _db = db;
        _schema = schema;
    }
    return self;
}

- (NSString *)realTable:(NSString *)name {
    if (_schema) {
        return [_schema stringByAppendingFormat:@".%@", name];
    }
    return name;
}

- (NSArray *)queryModel:(Class)modelClass where:(NSString *)where params:(NSDictionary *)params {
    NSString *sql = [JQDBSql selectModel:modelClass columes:nil].where(where).schema(_schema).build();
    FMResultSet *rs = [_db executeQuery:sql withParameterDictionary:params];
    return [rs jqdb_toArrayOfModel:modelClass];
}

static NSString *keysToWhere(NSArray *keys) {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[keys count]];
    for (NSString *key in keys) {
        [arr addObject:[NSString stringWithFormat:@"%@=:%@", key, key]];
    }
    NSString *where = [arr componentsJoinedByString:@" AND "];
    return where;
}

- (NSArray *)queryModel:(Class)modelClass keys:(NSArray *)keys params:(NSDictionary *)params {
    NSString *where = keysToWhere(keys);
    return [self queryModel:modelClass where:where params:params];
}

- (BOOL)deleteModel:(Class)modelClass where:(NSString *)where params:(NSDictionary *)params {
    NSString *sql = [JQDBSql delModel:modelClass].where(where).schema(_schema).build();
    return [_db executeUpdate:sql withParameterDictionary:params];
}

- (BOOL)deleteModel:(Class)modelClass keys:(NSArray *)keys params:(NSDictionary *)params {
    NSString *where = keysToWhere(keys);
    return [self deleteModel:modelClass where:where params:params];
}

- (BOOL)createTableOfModel:(Class)modelClass {
    NSString *sql = [JQDBSql sql_createTableOfModel:modelClass onSchema:_schema];
    return [_db executeUpdate:sql];
}

- (BOOL)createIndexOfModel:(Class)modelClass {
    NSString *sql = [JQDBSql sql_createIndexOfModel:modelClass onSchema:_schema];
    return [_db executeUpdate:sql];
}

- (BOOL)insertModel:(Class)modelClass params:(NSDictionary *)params {
    NSString *sql = [JQDBSql insertModel:modelClass].schema(_schema).build();
    NSMutableDictionary *mpa = [NSMutableDictionary dictionary];
    for (NSString *col in [modelClass jqdb_allColumes]) {
        id v = params[col];
        if (!v) {
            v = [NSNull null];
        }
        [mpa setObject:v forKey:col];
    }
    return [_db executeUpdate:sql withParameterDictionary:mpa];
}

- (BOOL)replaceModel:(Class)modelClass params:(NSDictionary *)params {
    NSString *sql = [JQDBSql replaceModel:modelClass].schema(_schema).build();
    NSMutableDictionary *mpa = [NSMutableDictionary dictionary];
    for (NSString *col in [modelClass jqdb_allColumes]) {
        id v = params[col];
        if (!v) {
            v = [NSNull null];
        }
        [mpa setObject:v forKey:col];
    }
    return [_db executeUpdate:sql withParameterDictionary:mpa];
}


- (BOOL)insertModel:(Class)modelClass paramsList:(NSArray *)paramsList {
    NSString *sql = [JQDBSql insertModel:modelClass].schema(_schema).build();
    for (NSDictionary *dict in paramsList) {
        [_db executeUpdate:sql withParameterDictionary:dict];
    }
    return YES;
}

- (BOOL)replaceModel:(Class)modelClass paramsList:(NSArray *)paramsList {
    NSString *sql = [JQDBSql replaceModel:modelClass].schema(_schema).build();
    BOOL success = YES;
    for (NSDictionary *dict in paramsList) {
      success = [_db executeUpdate:sql withParameterDictionary:dict];
        if (!success) {
            break;
        }
    }
    return success;
}

- (BOOL)updateModel:(Class)modelClass columes:(NSArray *)columes where:(NSString *)where params:(NSDictionary *)params {
    NSString *sql = [JQDBSql updateModel:modelClass columes:columes].where(where).schema(_schema).build();
    return [_db executeUpdate:sql withParameterDictionary:params];
}

- (BOOL)updateModel:(Class)modelClass columes:(NSArray *)columes keys:(NSArray *)keys params:(NSDictionary *)params {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[keys count]];
    for (NSString *key in keys) {
        [arr addObject:[NSString stringWithFormat:@"%@=:%@", key, key]];
    }
    NSString *where = [arr componentsJoinedByString:@" and "];
    return [self updateModel:modelClass columes:columes where:where params:params];
}

- (BOOL)updateModel:(Class)modelClass columes:(NSArray *)columes oRkeys:(NSArray *)keys params:(NSDictionary *)params {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[keys count]];
    for (NSString *key in keys) {
        [arr addObject:[NSString stringWithFormat:@"%@=:%@", key, key]];
    }
    NSString *where = [arr componentsJoinedByString:@" or "];
    return [self updateModel:modelClass columes:columes where:where params:params];
}

- (BOOL)updateObject:(id<JQDBModel>)object {
    Class clazz = [object class];
    __block NSArray *keys = nil;
    if ([clazz respondsToSelector:@selector(jqdb_tablePrimaryKeys)]) {
        keys = [clazz jqdb_tablePrimaryKeys];
    }
    if (!keys) {
        [[clazz jqdb_columeDefines] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                if ([obj isEqualToString:jqdb_PRIMARY_KEY]) {
                    keys = @[key];
                    *stop = YES;
                }
            }
            else if ([obj isKindOfClass:[NSArray class]]) {
                [(NSArray *)obj enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString *def, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([def isEqualToString:jqdb_PRIMARY_KEY]) {
                        keys = @[key];
                        *stop = YES;
                    }
                }];
            }
        }];
    }
    if ([keys count] == 0) {
        return NO;
    }
    NSMutableArray *arr = [[clazz jqdb_allColumes] mutableCopy];
    [arr removeObjectsInArray:keys];
    if ([arr count] == 0) {
        return NO;
    }
    return [self updateModel:[object class] columes:arr keys:keys params:[(NSObject<JQDBModel> *)object jqdb_modelToDictionary]];
}

- (BOOL)upgradeModel:(Class)modelClass {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA %@table_info('%@')",
                     _schema ? [_schema stringByAppendingString:@"."] : @"",  [modelClass jqdb_tableName]];
    FMResultSet *rs = [_db executeQuery:sql];
    NSMutableSet *columes = [NSMutableSet set];
    [rs jqdb_run:^(FMResultSet *me, BOOL *stop) {
        [columes addObject:[me stringForColumn:@"name"]];
    }];
    NSDictionary *defines = [modelClass jqdb_columeDefines];
    NSMutableSet *modelColumes = [NSMutableSet setWithArray:[defines allKeys]];
    [modelColumes minusSet:columes];
    __block BOOL success = YES;
    NSString *tableName = [self realTable:[modelClass jqdb_tableName]];
    [modelColumes enumerateObjectsUsingBlock:^(NSString *col, BOOL * _Nonnull stop) {
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@", tableName, priv_defineColume(col, defines[col])];
        success = [_db executeUpdate:sql];
        if (!success) {
            *stop = YES;
            NSLog(@"error: %@", [_db lastError]);
        }
    }];
    return success;
}

- (BOOL)dropTable:(NSString *)table {
    return [_db executeUpdate:[NSString stringWithFormat:@"DROP TABLE %@", [self realTable:table]]];
}

- (BOOL)insertObject:(id<JQDBModel>)object {
    return [self insertModel:[object class] params:[(NSObject *)object jqdb_modelToDictionary]];
}

- (BOOL)replaceObject:(id<JQDBModel>)object {
    return [self replaceModel:[object class] params:[(NSObject *)object jqdb_modelToDictionary]];
}

- (BOOL)insertModel:(Class)modelClass objects:(NSArray *)objects {
    return [self insertModel:modelClass paramsList:[objects jqdb_modelToDictionarys]];
}

- (BOOL)replaceModel:(Class)modelClass objects:(NSArray *)objects {
    return [self replaceModel:modelClass paramsList:[objects jqdb_modelToDictionarys]];
}

@end

@implementation FMDatabase (JQDBHelper)

- (JQDBHelper *)jqdb_helper {
    return [self jqdb_helper:nil];
}

- (JQDBHelper *)jqdb_helper:(NSString *)schema {
    return [[JQDBHelper alloc] initWithDB:self schema:schema];
}

@end
