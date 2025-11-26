//
//  DebugBudgetView.swift
//  Finance App
//
//  Created by Jas  on 11/24/25.
//

import SwiftUI

struct DebugBudgetView: View {
    @State private var scenarios: [String] = []
    @State private var selectedScenario: String?
    @State private var budget: String = "280"
    @State private var idToken: String = ""
    @State private var resultJSON: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Scenario") {
                    if scenarios.isEmpty {
                        Button("Load scenarios") { loadScenarios() }
                    } else {
                        Picker("Scenario", selection: $selectedScenario) {
                            ForEach(scenarios, id: \.self) { name in
                                Text(name).tag(Optional(name))
                            }
                        }
                    }
                }
                
                Section("Budget") {
                    TextField("Weekly budget", text: $budget)
                        .keyboardType(.numberPad)
                }
                
                Section("Auth Token") {
                    TextField("Firebase ID Token", text: $idToken)
                        .font(.system(size: 10, design: .monospaced))
                        .lineLimit(2)
                }
                
                Section {
                    Button {
                        runTest()
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Run /ai/weekly_summary")
                        }
                    }
                    .disabled(selectedScenario == nil || budget.isEmpty)
                }
                
                if let errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section("Raw AI JSON") {
                    ScrollView {
                        Text(resultJSON)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 150)
                }
            }
            .navigationTitle("AI Debug")
            .onAppear {
                loadScenarios()
            }
        }
    }
    
    // MARK: - Networking
    
    private func loadScenarios() {
        guard let url = URL(string: "http://localhost:5050/test/scenarios") else { return }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    let decoded = try JSONDecoder().decode(ScenariosResponse.self, from: data)
                    scenarios = decoded.scenarios
                    if selectedScenario == nil {
                        selectedScenario = scenarios.first
                    }
                } catch {
                    errorMessage = "Failed to decode scenarios"
                }
            }
        }.resume()
    }
    
    private func runTest() {
        guard let scenario = selectedScenario,
              let budgetValue = Int(budget),
              !idToken.isEmpty, // 👈 Check for token
              let scenarioURL = URL(string: "http://localhost:5050/test/scenario/\(scenario)"),
              let summaryURL = URL(string: "http://localhost:5050/ai/weekly_summary") else {
            errorMessage = "Token, scenario, or budget is missing."
            return
        }
        
        isLoading = true
        errorMessage = nil
        resultJSON = ""
        
        // 1️⃣ Get fake transactions for the scenario
        URLSession.shared.dataTask(with: scenarioURL) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let data = data else { return }
            
            do {
                // 2️⃣ Decode into our REAL Transaction model
                let txResponse = try JSONDecoder().decode(TransactionsResponse.self, from: data)
                
                // 3️⃣ Call your /ai/weekly_summary endpoint
                var request = URLRequest(url: summaryURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // 4️⃣ --- THIS IS THE AUTH FIX ---
                request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
                // ------------------------------
                
                // 5️⃣ --- THIS IS THE CRASH FIX ---
                // Use the Codable AISuggestionRequest and JSONEncoder
                let body = AISuggestionRequest(
                    transactions: txResponse.transactions,
                    weeklyBudget: budgetValue
                )
                request.httpBody = try JSONEncoder().encode(body)
                // ------------------------------
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        if let error = error {
                            errorMessage = error.localizedDescription
                            return
                        }
                        
                        // Check for 401/403 auth errors
                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                            errorMessage = "Error: \(httpResponse.statusCode) - \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"
                            
                            if let data = data, let errJSON = String(data: data, encoding: .utf8) {
                                resultJSON = errJSON
                            }
                            return
                        }
                        
                        guard let data = data else { return }
                        
                        // Pretty-print the JSON
                        do {
                            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                            resultJSON = String(data: prettyData, encoding: .utf8) ?? "<no data>"
                        } catch {
                            resultJSON = String(data: data, encoding: .utf8) ?? "<no data>"
                        }
                    }
                }.resume()
                
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Failed to decode scenario transactions: \(error)"
                }
            }
        }.resume()
    }
}
// MARK: - Models

// Use the *same* models as the main app
private struct ScenariosResponse: Codable {
    let scenarios: [String]
}

