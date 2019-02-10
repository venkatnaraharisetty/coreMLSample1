//
//  DetailViewController.swift
//  coreMLSample1
//
//  Created by Naraharisetty, Venkat on 2/9/19.
//  Copyright © 2019 Naraharisetty, Venkat. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var detailTextView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    //var displayImage? : UIImage;
    var displayText: String = ""
    var displayTitle: String = ""
    var displaydescription: String = ""
    var displayImage:UIImage!
    var displayConfidence: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action:#selector(self.addTapped))
        self.navigationItem.title = displayTitle;
         print("detailview title is : \n ", displayTitle)
         print("detailview text is : \n ", displaydescription)
        
        self.detailTextView.text = displaydescription
        self.titleLabel.text = displayTitle
        self.confidenceLabel.text = String("\(displayConfidence)%")
        self.imageView.image = displayImage
    }
    

    @objc func addTapped(){
        print("done tapped")
        navigationController?.popViewController(animated: true)
    }
}
