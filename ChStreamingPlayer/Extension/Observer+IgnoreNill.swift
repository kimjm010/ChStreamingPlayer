//
//  Observer+IgnoreNill.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/27/22.
//
//  Copyright since 2015 Showmax s.r.o.

import Foundation

import RxSwift

protocol OptionalWrapper
{
    associatedtype Wrapped
    
    var value: Wrapped? { get }
}

extension Optional: OptionalWrapper
{
    var value: Wrapped?
    {
        return self
    }
}

extension Observable where Element: OptionalWrapper
{
    /// This operator ignore `next` events which contains nil. Output is non-optional type.
    ///
    /// - Returns: Observable with non-optional type.
    func ignoreNil() -> Observable<E.Wrapped>
    {
        return flatMap({ element -> Observable<E.Wrapped> in
            
            guard let value = element.value else
            {
                return Observable<E.Wrapped>.empty()
                
            }
            
            return Observable<E.Wrapped>.just(value)
        })
    }
}
