//
//  RxHelpers.swift
//  Pods
//
//  Created by Arnaud Dorgans on 07/09/2017.
//
//

import RxAlamofireObjectMapper
import MappableObject
import Alamofire
import RealmSwift
import RxSwift
import ObjectMapper

extension ObservableType where E: DataRequest {
    
    public func getObject<T: MappableObject>(withType type: T.Type? = nil,
                          keyPath: String? = nil,
                          nestedKeyDelimiter: String? = nil,
                          context: RealmMapContext? = nil,
                          realm: Realm?,
                          mapError: Error,
                          statusCodeError:[Int:Error] = [:],
                          JSONMapHandler: ((Result<[String:Any]>, Any?, Int?, Error)->Result<[String:Any]>?)? = nil) -> Observable<T> {
        return self.getObject(withType: type, keyPath: keyPath, nestedKeyDelimiter: nestedKeyDelimiter, context: context, realm: realm, options: nil, mapError: mapError, statusCodeError: statusCodeError, JSONMapHandler: JSONMapHandler)
    }
    
    public func getObject<T: MappableObject>(withType type: T.Type? = nil,
                          keyPath: String? = nil,
                          nestedKeyDelimiter: String? = nil,
                          context: RealmMapContext? = nil,
                          realm: Realm? = nil,
                          options: RealmMapOptions,
                          mapError: Error,
                          statusCodeError:[Int:Error] = [:],
                          JSONMapHandler: ((Result<[String:Any]>, Any?, Int?, Error)->Result<[String:Any]>?)? = nil) -> Observable<T> {
        return self.getObject(withType: type, keyPath: keyPath, nestedKeyDelimiter: nestedKeyDelimiter, context: context, realm: realm, options: options as RealmMapOptions?, mapError: mapError, statusCodeError: statusCodeError, JSONMapHandler: JSONMapHandler)
    }
    
    private func getObject<T: MappableObject>(withType type: T.Type? = nil,
                          keyPath: String? = nil,
                          nestedKeyDelimiter: String? = nil,
                          context: RealmMapContext? = nil,
                          realm: Realm?,
                          options: RealmMapOptions?,
                          mapError: Error,
                          statusCodeError:[Int:Error] = [:],
                          JSONMapHandler: ((Result<[String:Any]>, Any?, Int?, Error)->Result<[String:Any]>?)? = nil) -> Observable<T> {
        return self.getJSON(withType: [String:Any].self, keyPath: keyPath, nestedKeyDelimiter: nestedKeyDelimiter, options: .allowFragments, error: mapError, statusCodeError: statusCodeError, JSONHandler: RxAlamofireObjectMapper.JSONHandler(type: T.self, JSONMapHandler: JSONMapHandler))
            .mapToObject(withType: type, context: context, realm: realm, options: options, mapError: mapError)
    }
    
    public func getObjectArray<T: MappableObject>(withType type: T.Type? = nil,
                               keyPath: String? = nil,
                               nestedKeyDelimiter: String? = nil,
                               context: RealmMapContext? = nil,
                               realm: Realm?,
                               mapError: Error,
                               statusCodeError:[Int:Error] = [:],
                               JSONMapHandler: ((Result<[[String:Any]]>, Any?, Int?, Error)->Result<[[String:Any]]>?)? = nil) -> Observable<[T]> {
        return getObjectArray(withType: type, keyPath: keyPath, nestedKeyDelimiter: nestedKeyDelimiter, context: context, realm: realm, options: nil, mapError: mapError, statusCodeError: statusCodeError, JSONMapHandler: JSONMapHandler)
    }
    
    public func getObjectArray<T: MappableObject>(withType type: T.Type? = nil,
                               keyPath: String? = nil,
                               nestedKeyDelimiter: String? = nil,
                               context: RealmMapContext? = nil,
                               realm: Realm? = nil,
                               options: RealmMapOptions,
                               mapError: Error,
                               statusCodeError:[Int:Error] = [:],
                               JSONMapHandler: ((Result<[[String:Any]]>, Any?, Int?, Error)->Result<[[String:Any]]>?)? = nil) -> Observable<[T]> {
        return getObjectArray(withType: type, keyPath: keyPath, nestedKeyDelimiter: nestedKeyDelimiter, context: context, realm: realm, options: options as RealmMapOptions?, mapError: mapError, statusCodeError: statusCodeError, JSONMapHandler: JSONMapHandler)
    }
    
    private func getObjectArray<T: MappableObject>(withType type: T.Type? = nil,
                                keyPath: String? = nil,
                                nestedKeyDelimiter: String?,
                                context: RealmMapContext?,
                                realm: Realm?,
                                options: RealmMapOptions?,
                                mapError: Error,
                                statusCodeError:[Int:Error],
                                JSONMapHandler: ((Result<[[String:Any]]>, Any?, Int?, Error)->Result<[[String:Any]]>?)?) -> Observable<[T]> {
        return self.getJSON(withType: [[String:Any]].self, keyPath: keyPath, nestedKeyDelimiter: nestedKeyDelimiter, options: .allowFragments, error: mapError, statusCodeError: statusCodeError, JSONHandler: RxAlamofireObjectMapper.JSONHandler(type: T.self, JSONMapHandler: JSONMapHandler))
            .mapToObjectArray(withType: type, context: context, realm: realm, options: options)
    }
}

extension Dictionary where Key == String, Value == Any {
    
    func mapToObject<T: MappableObject>(withType type: T.Type? = nil, context: RealmMapContext?, realm: Realm?, options: RealmMapOptions?) -> T? {
        let mapper = Mapper<T>(context: RealmMapContext.from(context: context, realm: realm, options: options))
        var object: T?
        try! (mapper.realm ?? Realm()).write {
            object = mapper.map(JSON: self)
        }
        return object
    }
}

extension ObservableType where E == [String:Any] {
    
    public func mapToObject<T: MappableObject>(withType type: T.Type? = nil, context: RealmMapContext? = nil, realm: Realm?, mapError: Error) -> Observable<T> {
        return mapToObject(withType: type, context: context, realm: realm, options: nil, mapError: mapError)
    }
    
    public func mapToObject<T: MappableObject>(withType type: T.Type? = nil, context: RealmMapContext? = nil, realm: Realm? = nil, options: RealmMapOptions, mapError: Error) -> Observable<T> {
        return mapToObject(withType: type, context: context, realm: realm, options: options as RealmMapOptions?, mapError: mapError)
    }
    
    internal func mapToObject<T: MappableObject>(withType type: T.Type? = nil, context: RealmMapContext?, realm: Realm?, options: RealmMapOptions?, mapError: Error) -> Observable<T> {
        return self.flatMap{ JSON -> Observable<T> in
            if let result = JSON.mapToObject(withType: type, context: context, realm: realm, options: options) {
                return .just(result)
            } else {
                return .error(mapError)
            }
        }
    }
}

extension Array where Element == [String:Any] {
    
    func mapToObjectArray<T: MappableObject>(withType type: T.Type? = nil, context: RealmMapContext?, realm: Realm?, options: RealmMapOptions?) -> [T] {
        let mapper = Mapper<T>()
        mapper.context = RealmMapContext.from(context: context, realm: realm, options: options)
        var array = [T]()
        try! (mapper.realm ?? Realm()).write {
            array = mapper.mapArray(JSONArray: self as [[String:Any]])
        }
        return array
    }
}
extension ObservableType where E == [[String:Any]] {
    
    public func mapToObjectArray<T: MappableObject>(withType type: T.Type? = nil, context: RealmMapContext? = nil, realm: Realm?) -> Observable<[T]> {
        return mapToObjectArray(withType: type, context: context, realm: realm, options: nil)
    }
    
    public func mapToObjectArray<T: MappableObject>(withType type: T.Type? = nil, context: RealmMapContext? = nil, realm: Realm? = nil, options: RealmMapOptions) -> Observable<[T]> {
        return mapToObjectArray(withType: type, context: context, realm: realm, options: options as RealmMapOptions?)
    }
    
    internal func mapToObjectArray<T: MappableObject>(withType type: T.Type? = nil, context: RealmMapContext?, realm: Realm?, options: RealmMapOptions?) -> Observable<[T]> {
        return self.map{ JSONArray -> [T] in
            return JSONArray.mapToObjectArray(withType: type, context: context, realm: realm, options: options)
        }
    }
}
