//
// AutoBindObject.m
// AutoBindObject
//
// Created by Cao Huu Loc on 1/7/16.
// Copyright © 2016 Cao Huu Loc. All rights reserved.
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
//

#import "AutoBindObject.h"
#import <objc/runtime.h>

@implementation AutoBindObject

#pragma mark - NSKeyValueCoding
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    //Does nothing
    //--> Don't raise exception
}

- (id)valueForUndefinedKey:(NSString *)key {
    return nil; //--> Don't raise exception
}

- (void)setValue:(id)value forKey:(NSString *)key {
    @try {
        if (![value isKindOfClass:[NSNull class]]) {
            if (![value isKindOfClass:[NSString class]] ||
                [value caseInsensitiveCompare:@"null"] != NSOrderedSame) {
                [super setValue:value forKey:key];
            }
        }
        else {
            [super setNilValueForKey:key];
        }
    }
    @catch (NSException *exception) {
    }
    @finally {
    }
}

#pragma mark - Public methods
+ (NSArray*)propertyNames {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    unsigned count;
    Class superClass = class_getSuperclass([self class]);
    if (superClass != NULL && [superClass isSubclassOfClass:[AutoBindObject class]]) {
        [arr addObjectsFromArray:[superClass propertyNames]];
    }
    NSString *name = [[NSString alloc] initWithUTF8String:class_getName([self class])];
    if ([name caseInsensitiveCompare:@"NSObject"] == NSOrderedSame ||
        [name caseInsensitiveCompare:@"AutoBindObject"] == NSOrderedSame) {
        return [NSArray array];
    }
    count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString *name = [[NSString alloc] initWithUTF8String:property_getName(property)];
        [arr addObject:name];
    }
    
    free(properties);
    NSArray *ret = [[NSArray alloc] initWithArray:arr];
    return ret;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        [self loadFromDictionary:dict];
    }
    return self;
}

- (void)loadFromJSONString:(NSString*)json {
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    id JSONObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    if ([JSONObject isKindOfClass:[NSDictionary class]]) {
        [self loadFromDictionary:JSONObject];
    }
}

- (void)loadFromDictionary:(NSDictionary*)dic {
    NSArray *keys = dic.allKeys;
    for (NSString *key in keys) {
        NSString *propertyName = [self propertyNameForKey:key];
        id value = [dic valueForKey:key];
        
        if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray *arrObjects = [self arrayOfDataFromArray:value propertyName:propertyName];
            if (arrObjects) {
                [self setValue:arrObjects forKey:propertyName];
            }
        } else if ([value isKindOfClass:[NSDictionary class]] &&
                   [self shouldUsePropertyToCreateObject:propertyName]) {
            Class class = [self classForPropertyName:propertyName];
            if (class && [class isSubclassOfClass:[AutoBindObject class]]) {
                id object = [[class alloc] initWithDictionary:value];
                [self setValue:object forKey:propertyName];
            } else if ([class isSubclassOfClass:[NSDictionary class]]) {
                id object = [[NSMutableDictionary alloc] initWithDictionary:value];
                [self setValue:object forKey:propertyName];
            }
        } else {
            [self setValue:value forKey:propertyName];
        }
    }
}

- (NSMutableDictionary*)toDictionary {
    NSMutableDictionary *ret;
    
    @autoreleasepool {
        NSArray *properties = [[self class] propertyNames];
        ret = [[NSMutableDictionary alloc] initWithCapacity:properties.count];
        for (NSString *key in properties) {
            if (![self shouldUsePropertyToGenDicData:key]) {
                continue;
            }
            NSString *dictionaryKey = [self dictionaryKeyForPropertyName:key];
            id object = [self valueForKey:key];
            if ([object isKindOfClass:[NSArray class]]) {
                NSMutableArray *arrDics = [self arrayUsedForDictionaryFromArrayData:object withKey:key];
                if (arrDics) {
                    [ret setValue:arrDics forKey:dictionaryKey];
                }
            } else if ([object isKindOfClass:[AutoBindObject class]]) {
                if ([object respondsToSelector:@selector(toDictionary)]) {
                    NSDictionary *dic = [object toDictionary];
                    [ret setValue:dic forKey:dictionaryKey];
                } else {
                    [ret setValue:object forKey:dictionaryKey];
                }
            } else {
                //Loc: Fix bug on some iOS versions, such as: iOS 9.3.5, or 10.3.2
                objc_property_t property = [self getPropertyTypeByName:key];
                char *type = property_copyAttributeValue(property, "T");
                if (type) {
                    NSString *s = [[NSString alloc] initWithUTF8String:type];
                    if (s && [s isEqualToString:@"c"]) {
                        //This is BOOL type with some iOS versions
                        BOOL b = [object boolValue];
                        object = [NSNumber numberWithBool:b];
                    }
                }
                free(type);
                //---
                
                [ret setValue:object forKey:dictionaryKey];
            }
        }
    }
    return ret;
}

- (NSString*)toJSONString {
    NSDictionary *dic = [self toDictionary];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:kNilOptions error:nil];
    if (!data) {
        return nil;
    }
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return json;
}

#pragma mark - Public methods (overridable)
- (NSString*)propertyNameForKey:(NSString*)key {
    return key;
}

- (NSString*)dictionaryKeyForPropertyName:(NSString*)name {
    return name;
}

- (Class)classForPropertyName:(NSString*)name {
    objc_property_t property = [self getPropertyTypeByName:name];
    if (property) {
        return [self getClassTypeOfProperty:property];
    }
    return nil;
}

- (Class)classForPropertyName:(NSString *)name atIndex:(NSInteger)index {
    return [self classForPropertyName:name];
}

- (BOOL)shouldUsePropertyToCreateObject:(NSString*)propertyName {
    return YES;
}

- (BOOL)shouldUsePropertyToGenDicData:(NSString*)propertyName {
    if ([propertyName isEqualToString:@"superclass"]) {
        return NO;
    }
    if ([propertyName isEqualToString:@"hash"]) {
        return NO;
    }
    return YES;
}

#pragma mark - Private methods
- (NSMutableArray*)arrayOfDataFromArray:(NSArray*)arrValues propertyName:(NSString*)propertyName {
    NSMutableArray *arrReturn = [[NSMutableArray alloc] initWithCapacity:arrValues.count];
    for (int i = 0; i < arrValues.count; i++) {
        id value = [arrValues objectAtIndex:i];
        
        if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray *arrObjects = [self arrayOfDataFromArray:value propertyName:propertyName];
            if (arrObjects) {
                [arrReturn addObject:arrObjects];
            }
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            Class class = [self classForPropertyName:propertyName atIndex:i];
            if (class && [class isSubclassOfClass:[AutoBindObject class]]) {
                id object = [[class alloc] initWithDictionary:value];
                [arrReturn addObject:object];
            }
        } else {
            [arrReturn addObject:value];
        }
    }
    return arrReturn;
}

- (NSMutableArray*)arrayUsedForDictionaryFromArrayData:(NSArray*)arrData withKey:(NSString*)key {
    NSMutableArray *arrReturn = [[NSMutableArray alloc] initWithCapacity:arrData.count];
    for (int i = 0; i < arrData.count; i++) {
        id value = [arrData objectAtIndex:i];
        
        if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray *arrObjects = [self arrayUsedForDictionaryFromArrayData:value withKey:key];
            if (arrObjects) {
                [arrReturn addObject:arrObjects];
            }
        } else if ([value isKindOfClass:[AutoBindObject class]]) {
            AutoBindObject *object = value;
            NSDictionary *dic = [object toDictionary];
            [arrReturn addObject:dic];
        } else {
            [arrReturn addObject:value];
        }
    }
    return arrReturn;
}

- (objc_property_t)getPropertyTypeByName:(NSString*)name {
    objc_property_t property = class_getProperty([self class], [name UTF8String]);
    return property;
}

- (Class)getClassTypeOfProperty:(objc_property_t)property {
    Class ret = nil;
    
    char *className = property_copyAttributeValue(property, "T");
    if (className) {
        NSString *s = [[NSString alloc] initWithUTF8String:className];
        int length = (int)s.length;
        if (length > 3) {
            if ( ([s hasPrefix:@"@\""]) && ([s hasSuffix:@"\""]) ) {
                NSRange range = NSMakeRange(2, length-3);
                NSString *name = [s substringWithRange:range];
                ret = NSClassFromString(name);
            }
        }
    }
    free(className);
    
    return ret;
}

@end
