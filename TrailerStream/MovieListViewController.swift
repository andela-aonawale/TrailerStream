//
//  MovieListViewController.swift
//  TrailerStream
//
//  Created by Ahmed Onawale on 11/17/15.
//  Copyright © 2015 Ahmed Onawale. All rights reserved.
//

import UIKit
import CoreData

class MovieListViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func handleSegementChange(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            fetchedResultsController = upcomingFetchedResultsController
        case 1:
            fetchedResultsController = popularFetchedResultsController
        default:
            break
        }
        performFetchWithCompletionHandler(nil)
        tableView.reloadData()
        saveSelectedSegmentIndex(sender.selectedSegmentIndex)
    }
    
    func saveSelectedSegmentIndex(index: Int) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(index, forKey: "index")
        defaults.synchronize()
    }
    
    func segmentedControlSavedIndex() -> Int? {
        return NSUserDefaults.standardUserDefaults().valueForKey("index") as? Int
    }
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Mark: - Fetched Results Controller
    
    var fetchedResultsController: NSFetchedResultsController!
    
    lazy var popularFetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Movie")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "type == %@", "popular")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: "popular")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        return fetchedResultsController
    }()
    
    lazy var upcomingFetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Movie")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "type == %@", "upcoming")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: "upcoming")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        return fetchedResultsController
    }()
    
    func showNetworkFailureAlert() {
        let alert = UIAlertController(title: "Unable to download new movie trailers.", message: nil, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func showStatusBarActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func hideStatusBarActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func performFetchWithCompletionHandler(completionHandler: (Void -> Void)?) {
        if fetchedResultsController.fetchedObjects!.isEmpty {
            showStatusBarActivityIndicator()
            if segmentedControl.selectedSegmentIndex == 0 {
                TheMovieDB.sharedInstance.fetchUpcomingMovies { result, error in
                    guard error == nil, let results = result?["results"] as? [[String: AnyObject]] else {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.showNetworkFailureAlert()
                            self.hideStatusBarActivityIndicator()
                            completionHandler?()
                        }
                        return
                    }
                    _ = results.map {
                        Movie(dictionary: $0, movieType: .Upcoming, context: self.sharedContext)
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                        self.hideStatusBarActivityIndicator()
                        CoreDataStackManager.sharedInstance().saveContext()
                        completionHandler?()
                    }
                }
            } else {
                TheMovieDB.sharedInstance.fetchPopularMovies { result, error in
                    guard error == nil, let results = result?["results"] as? [[String: AnyObject]] else {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.showNetworkFailureAlert()
                            self.hideStatusBarActivityIndicator()
                            completionHandler?()
                        }
                        return
                    }
                    _ = results.map {
                        Movie(dictionary: $0, movieType: .Popular, context: self.sharedContext)
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                        self.hideStatusBarActivityIndicator()
                        CoreDataStackManager.sharedInstance().saveContext()
                        completionHandler?()
                    }
                }
            }
        } else {
            completionHandler?()
        }
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        performFetchWithCompletionHandler { Void in
            refreshControl.endRefreshing()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        performFetchWithCompletionHandler(nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "handleRefresh:", forControlEvents: .ValueChanged)
        tableView.addSubview(refreshControl)
        segmentedControl.selectedSegmentIndex = segmentedControlSavedIndex() ?? 0
        if segmentedControl.selectedSegmentIndex == 0 {
            fetchedResultsController = upcomingFetchedResultsController
        } else {
            fetchedResultsController = popularFetchedResultsController
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case "Show Movie Detail":
            guard let navigationController = segue.destinationViewController as? UINavigationController,
                controller = navigationController.topViewController as? MovieDetailViewController else {
                    return
            }
            controller.movie = sender as! Movie
        default:
            break
        }
    }

}

extension MovieListViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            break
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
}

extension MovieListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Movie Cell") as! TaskCancelingTableViewCell
        let movie = fetchedResultsController.objectAtIndexPath(indexPath) as! Movie
        configureCell(cell, movie: movie)
        return cell
    }
    
    func configureCell(cell: TaskCancelingTableViewCell, movie: Movie) {
        var posterImage = UIImage(named: "placeHolderImage")
        
        cell.textLabel!.text = movie.title
        cell.imageView!.image = nil
        
        if movie.posterPath.isEmpty {
            posterImage = UIImage(named: "noImage")
        } else if movie.posterImage != nil {
            posterImage = movie.posterImage
        } else {
            let size = TheMovieDB.sharedInstance.config.posterSizes[1]
            let task = TheMovieDB.sharedInstance.taskForImageWithSize(size, filePath: movie.posterPath) { data, error in
                guard error == nil, let data = data else {
                    print("Poster download error: \(error!.localizedDescription)")
                    return
                }
                let image = UIImage(data: data)
                movie.posterImage = image
                dispatch_async(dispatch_get_main_queue()) {
                    cell.imageView!.image = image
                }
            }
            cell.taskToCancelifCellIsReused = task
        }
        
        cell.imageView!.image = posterImage
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections?[section]
        return sectionInfo?.numberOfObjects ?? 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let movie = fetchedResultsController.objectAtIndexPath(indexPath) as! Movie
        performSegueWithIdentifier("Show Movie Detail", sender: movie)
    }
    
}
