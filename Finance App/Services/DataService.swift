//
//  DataService.swift
//  Finance App
//
//  Created by Jas  on 4/19/25.
//

import Foundation

class DataService {
    static func loadSummariesFromBackend(
        accessToken: String,//require for authentication
        completion: @escaping ([AccountSummary]) -> Void//returns an array of AccountSummary
    ) {
        let urlString = "http://localhost:5050/summaries?access_token=\(accessToken)"
//        let urlString = "http://192.168.0.87:5050/summaries?access_token=\(accessToken)"
        //build an URL with accessToken
        guard let url = URL(string: urlString) else {//check if the url is valid or else
            return completion([])//return empty result
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in //starts an asynchronus http request
            // 1) catches network error
            if let error = error {
                return DispatchQueue.main.async { completion([]) }//if nil return empty array
            }
            // 2) Data check
            guard let data = data else {
                return DispatchQueue.main.async { completion([]) }//if nil return empty array
            }
            // 3) Decode the JSON resposne to SummariesResponse Model
            do {
                let wrapper = try JSONDecoder().decode(SummariesResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(wrapper.summaries)
                }
            } catch {
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
        .resume()
    }
    static func loadTransactions(// same as above - loadSummariesFromBackend
        accessToken: String,
        period: String,                       // “today” / “week” / “month”
        completion: @escaping ([Transaction]) -> Void //return an array of transaction
    ) {
        let urlString = "http://192.168.0.87:5050/transactions?access_token=\(accessToken)&period=\(period)"
        guard let url = URL(string: urlString) else {
            return DispatchQueue.main.async { completion([]) }
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                return DispatchQueue.main.async { completion([]) }
            }
            guard let data = data else {
                return DispatchQueue.main.async { completion([]) }
            }
            do {
                let resp = try JSONDecoder().decode(TransactionsResponse.self, from: data)
                DispatchQueue.main.async { completion(resp.transactions) }
            } catch {
                DispatchQueue.main.async { completion([]) }
            }
        }
        .resume()
    }
    static func loadTransactionsBetween(
            accessToken: String,
            startDate: String,
            endDate: String,
            completion: @escaping ([Transaction]) -> Void
        ) {
            // Build URLComponents for GET /transactions?access_token=…&start_date=…&end_date=…
            var comps = URLComponents(string: "http://192.168.0.87:5050/transactions")!
            comps.queryItems = [
                URLQueryItem(name: "access_token", value: accessToken),
                URLQueryItem(name: "start_date", value: startDate),
                URLQueryItem(name: "end_date", value: endDate)
            ]
            guard let url = comps.url else {
                return DispatchQueue.main.async { completion([]) }
            }

            URLSession.shared.dataTask(with: url) { data, _, error in
                if let _ = error {
                    return DispatchQueue.main.async { completion([]) }
                }
                guard let data = data else {
                    return DispatchQueue.main.async { completion([]) }
                }
                do {
                    let resp = try JSONDecoder().decode(TransactionsResponse.self, from: data)
                    DispatchQueue.main.async { completion(resp.transactions) }
                } catch {
                    DispatchQueue.main.async { completion([]) }
                }
            }
            .resume()
        }
}



