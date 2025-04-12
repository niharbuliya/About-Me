//
//  ViewController.swift
//  About Me
//
//  Created by Nihar Buliya on 13/04/25.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var textViewGitUrl: UITextView!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    
    var githubData : GitHubUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        makeAPICall()
    }
    func makeAPICall(){
        Task{
            self.githubData = try await getUser()
            await MainActor.run{
                setupUI()
                configureTextView()
                makeCallForImage()
            }
        }
        
    }
    
    func setupUI(){
        guard let data = githubData else {return}
        
        lblDescription.text = data.name
        lblName.text = data.bio
        
    }
    func makeCallForImage(){
        guard let data = githubData else {return}
        if let imgUrl = URL(string: data.avatarUrl ?? "") {
            Task{
                do {
                    let (imgData, _) = try await URLSession.shared.data(from: imgUrl)
                    if let image = UIImage(data: imgData) {
                        await MainActor.run {
                            imgView.image = image
                            imgView.layer.cornerRadius = 100
                        }
                    }
                }
                catch{
                    print("Failed to load image")
                }
            }
        }
    }
    
    func configureTextView(){
        guard let data = githubData else {return}
        
        let githubUrl = data.htmlUrl ?? ""
        let attributedString = NSMutableAttributedString(string: githubUrl )
        if let linkRange = githubUrl.range(of: githubUrl) {
            let nsRange = NSRange(linkRange, in: githubUrl)
            attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: nsRange)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
        }
        textViewGitUrl.attributedText = attributedString
        textViewGitUrl.textAlignment = .center
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(githubURLTapped))
        self.textViewGitUrl.addGestureRecognizer(tapGesture)
    }
  
    @objc func githubURLTapped(){
        if let url = URL(string:githubData?.htmlUrl ?? "") {
            UIApplication.shared.open(url)
        }
    }
    func getUser() async throws -> GitHubUser{
        let endPoint = "https://api.github.com/users/niharbuliya"
        guard let url = URL(string: endPoint) else{
            throw GHError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else{
            throw GHError.invalidResponse
        }
        
        do{
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let gitData = try decoder.decode(GitHubUser.self, from: data)
            print(gitData)
            return gitData
        }
        catch{
            throw GHError.invalidData
        }
    }
    
    
}
struct GitHubUser : Codable{
    let avatarUrl: String?
    let name : String?
    let bio : String?
    let htmlUrl : String?
    let login : String?
}

enum GHError : Error{
    case invalidURL
    case invalidResponse
    case invalidData
}

