//
//  MoviewDetailViewController.swift
//  TrailerStream
//
//  Created by Ahmed Onawale on 11/17/15.
//  Copyright © 2015 Ahmed Onawale. All rights reserved.
//

import UIKit
import YouTubePlayer

class MovieDetailViewController: UIViewController {
    
    var movie: Movie!
    @IBAction func close(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBOutlet weak var overview: UITextView!
    @IBOutlet weak var videoPlayer: YouTubePlayerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func showStatusBarActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func hideStatusBarActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.startAnimating()
        showStatusBarActivityIndicator()
        title = movie.title
        overview.text = movie.overview
        TheMovieDB.sharedInstance.keyForMovieWithID(movie.id) { result, error in
            guard error == nil,
                let results = result?["results"] as? [[String: AnyObject]],
                key = results.first?["key"] as? String else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.videoPlayer.hidden = true
                    self.activityIndicator.stopAnimating()
                    self.hideStatusBarActivityIndicator()
                    let alert = UIAlertController(title: "Trailer is unavailable for \(self.movie.title)", message: nil, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                return
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.videoPlayer.loadVideoID(key)
                self.activityIndicator.stopAnimating()
                self.hideStatusBarActivityIndicator()
            }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
