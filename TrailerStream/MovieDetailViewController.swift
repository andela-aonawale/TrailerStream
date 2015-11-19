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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = movie.title
        overview.text = movie.overview
        TheMovieDB.sharedInstance.keyForMovieWithID(movie.id) { result, error in
            guard error == nil,
                let results = result?["results"] as? [[String: AnyObject]],
                key = results.first?["key"] as? String else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.videoPlayer.hidden = true
                }
                return
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.videoPlayer.loadVideoID(key)
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
