//
//  BusinessesViewController.swift
//  Yelp
//
//  Created by Timothy Lee on 4/23/15.
//  Copyright (c) 2015 Timothy Lee. All rights reserved.
//

import UIKit
import SVProgressHUD
import DGElasticPullToRefresh

class BusinessesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    var businesses: NSMutableArray = []
    var filteredBusinesses = []
    
    @IBOutlet weak var tableView: UITableView!
    var searchBar = UISearchBar()
    var pages: Int = 0
    var originalSize: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        
        searchBar.delegate = self
        searchBar.sizeToFit()
        searchBar.showsCancelButton = true
        navigationItem.titleView = searchBar
        
        
        SVProgressHUD.showWithStatus("Loading")
        self.apiCall()
        
        let loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = UIColor(red: 78/255.0, green: 221/255.0, blue: 200/255.0, alpha: 1.0)
        tableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            
            self?.apiCall()
            self?.tableView.dg_stopLoading()
            
            }, loadingView: loadingView)
        tableView.dg_setPullToRefreshFillColor(UIColor(red: 255/255.0, green: 75/255.0, blue: 80/255.0, alpha: 1.0))
        tableView.dg_setPullToRefreshBackgroundColor(tableView.backgroundColor!)

/* Example of Yelp search with more search options specified
        Business.searchWithTerm("Restaurants", sort: .Distance, categories: ["asianfusion", "burgers"], deals: true) { (businesses: [Business]!, error: NSError!) -> Void in
            self.businesses = businesses
            
            for business in businesses {
        
                print(business.name!)
                print(business.address!)
            }
        }
*/
    }
    
    func apiCall() {
        Business.searchWithTerm(pages * originalSize, term: "Restaurants", completion: { (businesses: [Business]!, error: NSError!) -> Void in
            self.businesses.addObjectsFromArray(businesses)
            self.tableView.reloadData()
            
            for business in businesses {
                print(business.name!)
                print(business.address!)
            }
            self.originalSize = businesses.count
        })
        SVProgressHUD.dismiss()
        tableView.reloadData()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if let searchText = searchBar.text {
            let searchPredicate = NSPredicate(format: "name CONTAINS[c] %@", searchText)
            let filteredResult = businesses.filteredArrayUsingPredicate(searchPredicate)
            if filteredResult.count != 0 {
                filteredBusinesses = filteredResult
            } else {
                filteredBusinesses = []
            }
            tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.filteredBusinesses = []
        searchBar.resignFirstResponder()
        searchBar.text = ""
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = true
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredBusinesses.count != 0 {
            return filteredBusinesses.count
        } else {
            return businesses.count
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("BusinessCell", forIndexPath: indexPath) as! BusinessCell
        
        if (filteredBusinesses.count != 0) {
            cell.business = filteredBusinesses[indexPath.row] as! Business
        } else {
            cell.business = businesses[indexPath.row] as! Business
        }
        return cell 
    }
    
    var isMoreDataLoading = false
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (!isMoreDataLoading) {

            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            if(scrollView.contentOffset.y > scrollOffsetThreshold && tableView.dragging) {
                isMoreDataLoading = true
                
                SVProgressHUD.showWithStatus("Loading")
                self.pages++
                self.apiCall()
                self.isMoreDataLoading = false
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! BusinessCell
        performSegueWithIdentifier("detailsView", sender: cell)
    }
    
    

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "detailsView") {
            let cell = sender as! BusinessCell
            let indexPath = tableView.indexPathForCell(cell)
            let business: Business?
            if (filteredBusinesses.count != 0) {
                business = filteredBusinesses[(indexPath?.row)!] as? Business
            } else {
                business = businesses[(indexPath?.row)!] as? Business
            }
            let destinationViewController = segue.destinationViewController as! DetailsViewController
            destinationViewController.business = business
        } else if (segue.identifier == "mapView") {
            let destinationViewController = segue.destinationViewController as! MapViewController
            if (filteredBusinesses.count != 0) {
                destinationViewController.businesses = self.filteredBusinesses
            } else {
                destinationViewController.businesses = self.businesses
            }
        }
    }

}

extension UIScrollView {
    func dg_stopScrollingAnimation() {}
}
