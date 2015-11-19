//
//  Movie.swift
//  TrailerStream
//
//  Created by Ahmed Onawale on 11/17/15.
//  Copyright © 2015 Ahmed Onawale. All rights reserved.
//

import Foundation
import CoreData
import UIKit

enum MovieType: String {
    case Upcoming = "upcoming"
    case Popular = "popular"
}

class Movie: NSManagedObject {
    
    struct Keys {
        static let Title = "title"
        static let PosterPath = "poster_path"
        static let ReleaseDate = "release_date"
        static let ID = "id"
        static let Overview = "overview"
    }
    
    @NSManaged var title: String
    @NSManaged var id: NSNumber
    @NSManaged var posterPath: String
    @NSManaged var releaseDate: NSDate
    @NSManaged var overview: String
    @NSManaged var type: String
    
    var movieType: MovieType {
        get { return MovieType(rawValue: type)! }
        set { self.type = newValue.rawValue }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], movieType: MovieType, context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Movie", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        title = dictionary[Keys.Title] as! String
        id = dictionary[Keys.ID] as! Int
        posterPath = dictionary[Keys.PosterPath] as? String ?? ""
        overview = dictionary[Keys.Overview] as? String ?? ""
        self.movieType = movieType
        
        if let dateString = dictionary[Keys.ReleaseDate] as? String {
            if let date = TheMovieDB.sharedDateFormatter.dateFromString(dateString) {
                releaseDate = date
            }
        }
        
    }
    
    var posterImage: UIImage? {
        get {
            return TheMovieDB.Caches.imageCache.imageWithIdentifier(posterPath)
        }
        set {
            TheMovieDB.Caches.imageCache.storeImage(newValue, withIdentifier: posterPath)
        }
    }
    
}