//
//  MovieDetailViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var watchlistBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var favoriteBarButtonItem: UIBarButtonItem!
    
    var movie: Movie!
    
    var isWatchlist: Bool {
        return MovieModel.watchlist.contains(movie)
    }
    
    var isFavorite: Bool {
        return MovieModel.favorites.contains(movie)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = movie.title
        
        toggleBarButton(watchlistBarButtonItem, enabled: isWatchlist)
        toggleBarButton(favoriteBarButtonItem, enabled: isFavorite)
        guard let path = movie.posterPath else { return }
        TMDBClient.getPoster(path: path, completion: self.handleGetPosterResponse(data:error:))
    }
    
    @IBAction func whatchlistIsTapped(_ sender: UIBarButtonItem) {
          TMDBClient.addToWatchlistRequest(mediaType: "movie", mediaId: movie.id, watchlist: !isWatchlist, completion: self.handleAddToWatchlistResponse(is_success:error:))
    }
    
    
    @IBAction func favoriteButtonTapped(_ sender: UIBarButtonItem) {
        TMDBClient.markFavourite(mediaId: movie.id, toAdd: !isFavorite, completion: self.handleMarkFavouritesResponse(is_success:error:))
    }
    
    func toggleBarButton(_ button: UIBarButtonItem, enabled: Bool) {
        if enabled {
            button.tintColor = UIColor.primaryDark
        } else {
            button.tintColor = UIColor.gray
        }
    }
    func handleAddToWatchlistResponse(is_success: Bool, error: Error?) {
        if is_success {
            if isWatchlist {
                MovieModel.watchlist = MovieModel.watchlist.filter { $0 != self.movie }
                toggleBarButton(watchlistBarButtonItem, enabled: false)
            } else {
                MovieModel.watchlist.append(movie)
                toggleBarButton(watchlistBarButtonItem, enabled: true)
            }
        }
    }
    func handleMarkFavouritesResponse(is_success: Bool, error: Error?) {
        if is_success {
            if isFavorite {
                MovieModel.favorites = MovieModel.favorites.filter { $0 != self.movie }
                toggleBarButton(favoriteBarButtonItem, enabled: false)
            } else {
                MovieModel.favorites.append(movie)
                toggleBarButton(favoriteBarButtonItem, enabled: true)
            }
        }
    }
    func handleGetPosterResponse(data: Data?, error: Error?) {
        guard let data = data, let image = UIImage(data: data) else {
            return
        }
        imageView.image = image
    }
}
