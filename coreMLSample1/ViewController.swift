//
//  ViewController.swift
//  coreMLSample1
//
//  Created by Naraharisetty, Venkat on 2/5/19.
//  Copyright © 2019 Naraharisetty, Venkat. All rights reserved.
//

import UIKit
import AVKit
import CoreML
import Vision

class ViewController: UIViewController,UINavigationControllerDelegate, UIImagePickerControllerDelegate, AVCapturePhotoCaptureDelegate  {


    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    let captureSession = AVCaptureSession()
    let imageOutput = AVCapturePhotoOutput()
    var retreivedObjectName: String = ""
    var retreivedDescription:String = ""
    var retreivedImage:UIImage!
    var tapGesture:UITapGestureRecognizer!
    var receivedConfidence:Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureForImage))
        cameraView.addGestureRecognizer(tapGesture)
        addInputOutput(callback:{(status,error) in
            if(status){
                 captureSession.startRunning()
            } else {
                print("Cannot start camera")
                return
            }
           
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if cameraView.isHidden == true {
            self.view.addSubview(cameraView)
        }
    }
    
    // Adding Input and Output for 	 AVCapturesession
    func addInputOutput(callback:(Bool,Error?)->Void){
        captureSession.sessionPreset = .photo
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            callback(false, "captureDevice error" as? Error)
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            callback(false, "add input output error" as? Error)
            return
        }
        imageOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecType.jpeg])], completionHandler: nil)
        captureSession.addInput(input)
        captureSession.addOutput(imageOutput)
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraView.layer.addSublayer(previewLayer)
        previewLayer.frame = self.view.frame
        previewLayer.frame.size.height = cameraView.frame.size.height
        callback(true,nil)
    }

   
    // Taking photo on tap on Camera screen
   @objc func tapGestureForImage() {
        if imageOutput.connection(with: AVMediaType.video) != nil{
            let settings = AVCapturePhotoSettings()
            imageOutput.capturePhoto(with: settings, delegate: self)
        }
        cameraView.addSubview(activityView)
        activityView.startAnimating()
    self.cameraView.removeGestureRecognizer(tapGesture)

    }
    
    // Delegate method after cpaturing image
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            print("error occured in capturing photot")
        }
        if let dataImage = photo.fileDataRepresentation(){
             let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef:CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImage.Orientation.right)
            retreivedImage = image
            detect(image: image)
        } else {
            print("Image could not be captured");
        }
    }
    
    
    // Image recongnition from Inception Model
    func detect(image:UIImage){
        guard let convertedImage = CIImage(image: image) else {
            fatalError("COuld not convert image")
        }
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("cannot find model")
        }
        let request = VNCoreMLRequest(model: model) { (request,error) in
            let classification = request.results?.first as? VNClassificationObservation
            let mainObjectName = classification?.identifier ?? nil
            self.receivedConfidence = classification?.confidence  ?? 0.0
            let objectArray = mainObjectName?.components(separatedBy: ",")
            let objectName = objectArray?[0]
            if let objectName = objectName {
                self.retreivedObjectName = objectName
                self.callWikiPedia(objectName: objectName, image: image)
            }
        }
        let handler = VNImageRequestHandler(ciImage: convertedImage)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }

    
    // Calling wikipedia through service
    func callWikiPedia(objectName: String, image:UIImage){
     print("In wikipedia \n " ,objectName)
        getDataFromWiki(objectName: objectName, callback:{(success,response,error) in
            print("callback done")
            if(success){
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "detailViewSeque", sender: self)
                    //self.activityView.removeFromSuperview()
                    self.activityView.stopAnimating()
                    self.cameraView.addGestureRecognizer(self.tapGesture)
                }
            } else {
                print("callback error")
            }
            
        })
    }
    
    // Get data from wikipedia service and giving data back through callbacks
    func getDataFromWiki(objectName:String,  callback:@escaping (Bool, Any?, Error?) -> Void){
        //DispatchQueue.global().asyncAfter(deadline: .now() + 3)
        let urlObject : String = objectName.replacingOccurrences(of: " ", with: "%20")
        let urlString :String = "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro=&explaintext=&indexpageids=&redirects=1&titles=\(urlObject)"
        print("url string is /n", urlString)
        //let url:URL = URL.init(string: urlString)!
        guard let url = URL(string: urlString) else { return}
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request){ (data:Data?, response:URLResponse?, error:Error?) in
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]{
                        if let query = json["query"] as? [String:Any] {
                            if let page = query["pageids"] as? [String]{
                                if let pageID = page[0] as? String {
                                    if let descriptionquery = json["query"] as? [String:Any]{
                                        if let descriptionpage = descriptionquery["pages"] as? [String:Any]{
                                            if let descriptionID = descriptionpage[pageID] as? [String:Any]{
                                                if let description = descriptionID["extract"] as? String{
                                                    self.retreivedDescription = description
                                                    print("this is description \n" , description)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                   callback(true,self.description,nil)
                }catch{
                    print("Error in try catch")
                    callback(false,nil,error)
                }
            }
            
        }
        task.resume()
        print("callback about to happen")
    }
    
    // Move to Image screen and send data to the controller through segues.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("In segue function");
        let detailVC = segue.destination as! DetailViewController
        detailVC.displayTitle = retreivedObjectName;
        detailVC.displaydescription = retreivedDescription;
        detailVC.displayImage = retreivedImage;
        detailVC.displayConfidence = round(receivedConfidence * 100);
    }
    
}

