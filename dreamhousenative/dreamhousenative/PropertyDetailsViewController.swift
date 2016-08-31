//
//  PropertyDetailsViewController.swift
//  DHNative
//
//  Created by QUINTON WALL on 7/27/16.
//  Copyright © 2016 Quinton Wall. All rights reserved.
//

import UIKit
import ENSwiftSideMenu
import SDWebImage
import MapKit
import Spring
import UberRides
import CoreLocation



class PropertyDetailsViewController : UIViewController, ENSideMenuDelegate {
    
    var property: Property?
    let regionRadius: CLLocationDistance = 150
    var propertyLocation : CLLocation?
    let locationManger:CLLocationManager = CLLocationManager()
    
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var bathroomView: UIView!
    @IBOutlet weak var bedroomsView: UIView!
    @IBOutlet weak var askingpriceView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var buttonBarView: UIView!
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var propertyImage: UIImageView!
    @IBOutlet weak var numBedroomsLabel: UILabel!
    @IBOutlet weak var numBathsLabel: UILabel!
    @IBOutlet weak var askingPriceLabel: UILabel!
    @IBOutlet weak var brokerNameLabel: UILabel!
    @IBOutlet weak var brokerTitleLabel: UILabel!
    @IBOutlet weak var brokerProfileImage: UIImageView!
    

    //button bar
    @IBOutlet weak var liveAgentButton: SpringButton!
    @IBOutlet weak var shareButton: SpringButton!
    @IBOutlet weak var favoriteButton: SpringButton!
    @IBOutlet weak var brokerDetailsButton: UIButton!
    var uberButton: RideRequestButton?
    
    @IBOutlet weak var uberView: UIView!
    
    let items: [(icon: String, color: UIColor, text: String)] = [
        ("car-logo-small", UIColor(red:0.22, green:0.74, blue:0, alpha:1), "Uber"),
        ("food-logo-small", UIColor(red:0.96, green:0.23, blue:0.21, alpha:1), "Yelp!"),
       
        ]
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //fetch the image first to kick of the fetch thread
        self.propertyImage.sd_setImageWithURL(NSURL(string: property!.pictureImageURL!), placeholderImage: UIImage(named: "full-size-icon"))
        
        favoriteButton.setImage(UIImage(named: "favorite-red-small"), forState: UIControlState.Selected)
        favoriteButton.setTitle("   Unfavorite", forState: UIControlState.Selected)
        if(property!.isFavorite) {
            favoriteButton.selected = true
            print("Is a favorite")
            
        }
        
        mapView.layer.cornerRadius = mapView.frame.size.height / 2
        mapView.layer.masksToBounds = true
        mapView.layer.borderColor = AppDefaults.dreamhouseGreen.CGColor
        mapView.layer.borderWidth = 2.0
        
        
        titleLabel.text = property?.title
        descriptionLabel.text = property?.description
        
        numBathsLabel.text = property?.numberOfBaths?.stringValue
        
         numBedroomsLabel.text = property?.numberOfBeds?.stringValue
        
        askingPriceLabel.text = property?.price
        
        brokerNameLabel.text = property?.brokerName
        brokerTitleLabel.text = property?.brokerTitle
        brokerProfileImage.sd_setImageWithURL(NSURL(string: property!.brokerImageURL!))
        brokerProfileImage.layer.cornerRadius = brokerProfileImage.frame.size.height / 2
        brokerProfileImage.layer.masksToBounds = true
        brokerProfileImage.layer.borderColor = AppDefaults.dreamhouseBlreen.CGColor
        brokerProfileImage.layer.borderWidth = 1.0
        
        
       self.backgroundImage.sd_setImageWithURL(NSURL(string: property!.pictureImageURL!) )
        backgroundImage.blurImageLightly()
        
     
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sideMenuController()?.sideMenu?.delegate = self
         SCServiceCloud.sharedInstance().sos.addDelegate(self)
        
        //set the map after load for nice zoom effect.
        propertyLocation = CLLocation(latitude: self.property!.latitude!, longitude: self.property!.longitude!)
        centerMapOnLocation(propertyLocation!)
        
        addUberButton()
        
        
        locationManger.delegate = self
        
        if !checkLocationServices() {
            locationManger.requestWhenInUseAuthorization()
        }
        
    }
    
    private func addUberButton() {
        uberButton = buildRideRequestWidgetButton(.Native)
        uberButton?.colorStyle = .White
        uberView.addSubview(uberButton!)
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,regionRadius * 2.0, regionRadius * 2.0)
         let objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = location.coordinate
        objectAnnotation.title = property?.title
        self.mapView.addAnnotation(objectAnnotation)
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    private func buildRideRequestWidgetButton(loginType: LoginType) -> RideRequestButton {
        let loginManager = LoginManager(loginType: loginType)
        let requestBehavior = RideRequestViewRequestingBehavior(presentingViewController: self, loginManager: loginManager)
        requestBehavior.modalRideRequestViewController.delegate = self
        
        let builder = RideParametersBuilder()
        builder.setPickupToCurrentLocation()
        //builder.setDropoffLocation(propertyLocation!)
        builder.setDropoffLocation(propertyLocation!, address: property?.address)
        let rideParameters = builder.build()
        let btn  = RideRequestButton(rideParameters: rideParameters, requestingBehavior: requestBehavior)
        return btn
    }
    
    
    private func checkLocationServices() -> Bool {
        let locationEnabled = CLLocationManager.locationServicesEnabled()
        let locationAuthorization = CLLocationManager.authorizationStatus()
        let locationAuthorized = locationAuthorization == .AuthorizedWhenInUse || locationAuthorization == .AuthorizedAlways
        
        return locationEnabled && locationAuthorized
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "BrokerDetails" {
            let brokersViewController = segue.destinationViewController as! BrokerSelectionViewController
            brokersViewController.brokerId = self.property?.brokerId
        }
    }
    
    private func showMessage(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let okayAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(okayAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    //MARK: - 
    //MARK: Button Actions
    @IBAction func liveAgentTapped(sender: AnyObject) {
        let btn: SpringButton = sender as! SpringButton
        btn.animation = "zoomOut"
        btn.animate()
        btn.animation = "zoomIn"
        btn.animate()
        
       //see https://resources.docs.salesforce.com/servicesdk/1/0/en-us/pdf/service_sdk_ios.pdf
        
        
       SCServiceCloud.sharedInstance().sos.startSessionWithOptions(AppDefaults.getSOSOptions())
     

    }
    
    @IBAction func shareButtonTapped(sender: AnyObject) {
        let btn: SpringButton = sender as! SpringButton
        btn.animation = "zoomOut"
        btn.animate()
        btn.animation = "zoomIn"
        btn.animate()
    }
    
    @IBAction func favoriteButtonTapped(sender: AnyObject) {
        let btn: SpringButton = sender as! SpringButton
        btn.animation = "zoomOut"
        btn.animate()
        btn.animation = "zoomIn"
        btn.animate()

        
        
        if(!property!.isFavorite) {
            
            //let d : NSDictionary = property!.getDictionaryToSaveFavorite()
            
            let d : NSDictionary = [
                "Property__c" : property!.propertyId!,
                "User__c" : AppDefaults.getUserId()
            ]
            
            let request = SFRestAPI.sharedInstance().requestForCreateWithObjectType("Favorite__c", fields: d as? [String : AnyObject] )
            
            SFRestAPI.sharedInstance().sendRESTRequest(request, failBlock: { error in
               
                let alertController = UIAlertController(title: "Dreamhouse", message:   "Something went wrong: \(error)", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
                
            }) {response in
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.favoriteButton.selected = true
                    self.property?.isFavorite = true
                }
            }

            
        } else {
            
            let request = SFRestAPI.sharedInstance().requestForDeleteWithObjectType("Favorite__c", objectId: property!.favoriteId!)
            SFRestAPI.sharedInstance().sendRESTRequest(request, failBlock: { error in
                
                let alertController = UIAlertController(title: "Dreamhouse", message:   "Something went wrong: \(error)", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
                
            }) {response in
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.favoriteButton.selected = false
                    self.property?.isFavorite = false
                }
            }
 
        }
    }
    
    @IBAction func brokerDetailsTapped(sender: AnyObject) {
        self.performSegueWithIdentifier("BrokerDetails", sender: self)
        
    }
    
}

extension PropertyDetailsViewController : SOSDelegate {
    
    func sos(sos: SOSSessionManager!, stateDidChange current: SOSSessionState, previous: SOSSessionState) {
        if (current == SOSSessionState.Connecting) {
            print("connecting")
        }
    }
    
    func sosDidStart(sos: SOSSessionManager!) {
        print("start")
    }
    
    func sosDidConnect(sos: SOSSessionManager!) {
        print("connected")
    }
    
    func sos(sos: SOSSessionManager!, didError error: NSError!) {
        let desc = error.localizedDescription
        let errorCode :Int = error.code
        print("something went wrong: \(desc) \(errorCode)")
        
        //todo: show dialog on error
        switch (errorCode) {
        case SOSErrorCode.SOSNoAgentsAvailableError.rawValue:
            print("Noagent")
            break
        default:
            break
        }
        
        
    }

}

//MARK: ModalViewControllerDelegate

extension PropertyDetailsViewController : ModalViewControllerDelegate {
    func modalViewControllerDidDismiss(modalViewController: ModalViewController) {
        print("did dismiss")
    }
    
    func modalViewControllerWillDismiss(modalViewController: ModalViewController) {
        print("will dismiss")
    }
}

//MARK: CLLocationManagerDelegate

extension PropertyDetailsViewController : CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .Denied || status == .Restricted {
            showMessage("Location Services disabled.")
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManger.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        locationManger.stopUpdatingLocation()
        showMessage("There was an error locating you.")
    }
}

extension PropertyDetailsViewController : RideRequestViewControllerDelegate {
    func rideRequestViewController(rideRequestViewController: RideRequestViewController, didReceiveError error: NSError) {
        let errorType = RideRequestViewErrorType(rawValue: error.code) ?? .Unknown
        // Handle error here
        switch errorType {
        case .AccessTokenMissing:
            print(error.description)
            break
        case .AccessTokenExpired:
            print(error.description)
            break
        case .NetworkError:
            print(error.description)
            break
        case .NotSupported:
            print(error.description)
            break
        case .Unknown:
            print(error.description)
            break
        }
    }
}

