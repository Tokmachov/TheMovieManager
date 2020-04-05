//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = "9c1cf0e4b5802d5343d3337546885fa1"
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        static let token = "/authentication/token/new"
        case getWatchlist
        case getFavourites
        case getRequestToken
        case login
        case createSession
        case logout
        case searchMovies(String)
        case addToWatchList
        case addToFavourites
        case poster(String)
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getFavourites: return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam +
                "&session_id=\(Auth.sessionId)"
            case .getRequestToken: return Endpoints.base + Endpoints.token + Endpoints.apiKeyParam
            case .login:
                return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .createSession:
                return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .logout:
                return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
            case .searchMovies(let searchQuery):
                return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
            case .addToWatchList:
                return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .addToFavourites:
                return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .poster(let path):
                return "https://image.tmdb.org/t/p/w500/" + path
            }
            
        }
        
        var url: URL {
            print(stringValue)
            return URL(string: stringValue)!
        }
    }
    class func taskForGetRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            do {
                let response = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(response, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        return task
    }
    class func taskForPOSTRequest<RequestType: Encodable, ResponseType: Decodable>(
        url: URL,
        body: RequestType,
        responseType: ResponseType.Type,
        completion: @escaping (ResponseType?, Error?) -> ()
    ) {
        var request = URLRequest(url: url)
        let encodedBody = try! encoder.encode(body)
        request.httpMethod = "POST"
        request.httpBody = encodedBody
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            do {
                let receivedOject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(receivedOject, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
    }
    class func taskForDeleteRequest<RequestType: Encodable, ResponseType: Decodable>(
        url: URL,
        body: RequestType,
        responseType: ResponseType.Type,
        completion: @escaping (ResponseType?, Error?) -> ()
    ) {
        let encodedBody = try! encoder.encode(body)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.httpBody = encodedBody
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            do {
                let responseOject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseOject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        _  = taskForGetRequest(url: Endpoints.getWatchlist.url, responseType: MovieResults.self) { (movies, error) in
            guard let movies = movies else {
                completion([], error)
                return
            }
            completion(movies.results, nil)
        }
    }
    class func getFavourites(completion: @escaping ([Movie], Error?) -> Void) {
        let url = TMDBClient.Endpoints.getFavourites.url
        _ = taskForGetRequest(url: url, responseType: MovieResults.self) { (movieResults, error) in
            guard let movieResults = movieResults else {
                completion([], error)
                return
            }
            completion(movieResults.results, nil)
        }
    }
    class func getToken(completion: @escaping (Bool, Error?) -> ()) {
        let url = TMDBClient.Endpoints.getRequestToken.url
        _ = taskForGetRequest(url: url, responseType: RequestTokenResponse.self) { (tokenResponse, error) in
            guard let tokenResponse = tokenResponse else {
                completion(false, error)
                return
            }
            TMDBClient.Auth.requestToken = tokenResponse.token
            completion(true, error)
        }
    }
    class func login(userName: String, passWord: String, completion: @escaping (Bool, Error?) -> (Void)) {
        let body = LoginRequest(userName: userName, password: passWord, requestToken: TMDBClient.Auth.requestToken)
        let url = TMDBClient.Endpoints.login.url
        taskForPOSTRequest(url: url, body: body, responseType: RequestTokenResponse.self) { (requestTokenResponse, error) in
            guard let response = requestTokenResponse else {
                completion(false, error)
                return
            }
            print("Token: \(response.token)")
            TMDBClient.Auth.requestToken = response.token
            completion(true, error)
        }
    }
    class func requestSessionId(completion: @escaping (Bool, Error?) -> ()) {
        let url = TMDBClient.Endpoints.createSession.url
        let body = PostSession(requestToken: TMDBClient.Auth.requestToken)
        taskForPOSTRequest(url: url, body: body, responseType: SessionResponse.self) { (sessionResponse, error) in
            guard let sessionResponse = sessionResponse else {
                completion(false, error)
                return
            }
            TMDBClient.Auth.sessionId = sessionResponse.sessionId
            completion(true, nil)
        }
    }
    class func logoutRequest(completion: @escaping () -> ()) {
        let body = LogoutRequest(sessionID: TMDBClient.Auth.sessionId)
        let url = TMDBClient.Endpoints.logout.url
        taskForDeleteRequest(url: url, body: body, responseType: DeleteSessionResponse.self) { (response, error) in
            guard let response = response else {
                fatalError("Logout error \(error!)")
            }
            if response.success {
                print("Logout is success")
            } else {
                print("Logout falure")
            }
            TMDBClient.Auth.accountId = 0
            TMDBClient.Auth.requestToken = ""
            TMDBClient.Auth.sessionId = ""
            completion()
        }
    }
    class func searchRequest(query: String, completion: @escaping ([Movie], Error?) -> ()) -> URLSessionTask {
        let url = TMDBClient.Endpoints.searchMovies(query).url
        let task = taskForGetRequest(url: url, responseType: MovieResults.self) { (movieResults, error) in
            guard let movieResults = movieResults else {
                completion([], error)
                return
            }
            completion(movieResults.results, nil)
        }
        return task
    }
    class func addToWatchlistRequest(mediaType: String, mediaId: Int, watchlist: Bool, completion: @escaping (Bool, Error?) -> ()) {
        let url = TMDBClient.Endpoints.addToWatchList.url
        let body = MarkWatchList(mediaType: mediaType, mediaId: mediaId, watchlist: watchlist)
        taskForPOSTRequest(url: url, body: body, responseType: TMDBResponse.self) { (response, error) in
            guard let response = response else {
                completion(false, error)
                return
            }
            print(response)
            if response.statusCode == 1 ||
            response.statusCode == 12 ||
            response.statusCode == 13 {
                completion(true, nil)
            } else {
                completion(false, nil)
            }
        }
    }
    class func markFavourite(mediaId: Int, toAdd: Bool, completion: @escaping (Bool, Error?) -> ()) {
        let url = Endpoints.addToFavourites.url
        let body = MarkFavourite(mediaType: "movie", mediaId: mediaId, favorite: toAdd)
        taskForPOSTRequest(url: url, body: body, responseType: TMDBResponse.self) { (response, error) in
            guard let response = response else {
                completion(false, error)
                return
            }
            if response.statusCode == 1 ||
                response.statusCode == 12 ||
                response.statusCode == 13 {
                completion(true, nil)
            } else {
                completion(false, nil)
            }
        }
    }
    class func getPoster(path: String, completion: @escaping (Data?, Error?) -> ()) {
        let url = Endpoints.poster(path).url
        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            DispatchQueue.main.async {
                completion(data, nil)
            }
        }
        task.resume()
    }
}

