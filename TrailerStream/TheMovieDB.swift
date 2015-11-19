//
//  APIClient.swift
//  TrailerStream
//
//  Created by Ahmed Onawale on 11/17/15.
//  Copyright © 2015 Ahmed Onawale. All rights reserved.
//

import Foundation

class TheMovieDB {
    
    private struct API {
        static let BASE_URL = "https://api.themoviedb.org"
        static let POPULAR_PATH = "/3/movie/popular"
        static let UPCOMING_PATH = "/3/movie/upcoming"
        static let KEY = "b34c51e8e01d3bea915b0e60190728bd"
    }
    
    // MARK: - All purpose task method for images
    
    func taskForImageWithSize(size: String, filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        let baseURL = NSURL(string: config.secureBaseImageURLString)!
        let url = baseURL.URLByAppendingPathComponent(size).URLByAppendingPathComponent(filePath)
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                let newError = TheMovieDB.errorForData(data, response: response, error: error)
                completionHandler(imageData: nil, error: newError)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        task.resume()
        return task
    }
    
    private func buildURLWithPath(path: String)-> NSURL {
        let URLComponents = NSURLComponents(string: API.BASE_URL)!
        URLComponents.path = path
        URLComponents.queryItems = queryItemsFromDictionary(["api_key": API.KEY])
        return URLComponents.URL!
    }

    func keyForMovieWithID(id: NSNumber, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        let url = buildURLWithPath("/3/movie/\(id)/videos")
        return requestWithURL(url, completionHandler: completionHandler)
    }
    
    func fetchUpcomingMovies(completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        let url = buildURLWithPath(API.UPCOMING_PATH)
        return requestWithURL(url, completionHandler: completionHandler)
    }
    
    func fetchPopularMovies(completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        let url = buildURLWithPath(API.POPULAR_PATH)
        return requestWithURL(url, completionHandler: completionHandler)
    }
    
    private func requestWithURL(url: NSURL, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        let task = session.dataTaskWithURL(url) { data, response, error in
            if let error = error {
                let newError = TheMovieDB.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                TheMovieDB.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        task.resume()
        return task
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    // MARK: - Shared Date Formatter
    
    class var sharedDateFormatter: NSDateFormatter  {
        
        struct Singleton {
            static let dateFormatter = Singleton.generateDateFormatter()
            
            static func generateDateFormatter() -> NSDateFormatter {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-mm-dd"
                
                return formatter
            }
        }
        
        return Singleton.dateFormatter
    }
    
    // MARK: - Helpers
    
    
    // Try to make a better error, based on the status_message from TheMovieDB. If we cant then return the previous error
    
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if data == nil {
            return error
        }
        
        do {
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
            
            if let parsedResult = parsedResult as? [String : AnyObject], errorMessage = parsedResult[TheMovieDB.Keys.ErrorStatusMessage] as? String {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                return NSError(domain: "TMDB Error", code: 1, userInfo: userInfo)
            }
            
        } catch _ {}
        
        return error
    }
    
    // Parsing the JSON
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHandler) {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    // MARK: - Shared Instance
    
    static let sharedInstance = TheMovieDB()
    
    var config = Config.unarchivedInstance() ?? Config()
    
    private func queryItemsFromDictionary(dictionary: [String: String]) -> [NSURLQueryItem] {
        return dictionary.map() {
            return NSURLQueryItem(name: $0.0, value: $0.1)
        }
    }
    
    typealias CompletionHandler = (result: AnyObject?, error: NSError?) -> Void
    
    private var session: NSURLSession
    
    init() {
        session = NSURLSession.sharedSession()
    }
    
}
