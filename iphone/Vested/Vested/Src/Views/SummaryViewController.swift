//
//  SummaryViewController.swift
//  Vested
//
//  Created by ncurtis on 1/10/15.
//  Copyright (c) 2015 noelcurtis. All rights reserved.
//

import UIKit

class SummaryViewController : UITableViewController, CellDetailButtonDelegate {

    var addButton: UIBarButtonItem!

    let restrictedStockOptionDao = RestrictedOptionGrantDao(managedObjectContext: PersistenceService.sharedInstance.managedObjectContext!)
    let restrictedStockVestingCalulator = RestrictedStockOptionGrantCalculator()
    
    var stockPlans: Array <AnyObject> = []
    var expandedIndexPaths:[NSIndexPath] = []
    
    var deleteEditing = false
    var summaryCellUpdating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTableView()
    }
    
    override func viewDidAppear(animated: Bool) {
        setupTableView()
        loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupTableView() {
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.backgroundView = UIImageView(image: UIImage(named: "background"))
        tableView.registerClass(SummaryCellV2.self, forCellReuseIdentifier: SummaryCellV2.REUSE_IDENTIFIER)
    }
    
    func loadData() {
        stockPlans = restrictedStockOptionDao.findAllRestrictedOptionGrants()
        tableView.reloadData()
    }
    
    func setupNavBar() {
        // setup the buttons
        addButton = UIBarButtonItem(image: UIImage(named: "add_button"), style: UIBarButtonItemStyle.Plain, target: self, action: "pushRestrictedStockPlanDetailView")

        let navTitle = UIImage(named: "nav_title_vested")
        let navTitleView = UIImageView(image: navTitle)
        self.navigationItem.titleView = navTitleView
        self.navigationItem.titleView?.hidden = false
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationItem.rightBarButtonItem = addButton
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.hidesBackButton = true
        
        self.navigationController?.navigationBar.barTintColor = UIColor(rgba: "#252A2D")
        self.navigationController?.navigationBar.translucent = false
    }
    
    func pushRestrictedStockPlanDetailView() {
        self.navigationController?.pushViewController(RestrictedPlanDetailViewController(style: UITableViewStyle.Grouped), animated: true)
    }

    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            let toRemove = stockPlans[indexPath.row] as StockPlan
            restrictedStockOptionDao.deleteStockPlan(toRemove)
            stockPlans.removeAtIndex(indexPath.row)
            tableView.reloadData()
        }
        deleteEditing = false
    }
    
    override func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        NSLog("Started editing row and index path")
        deleteEditing = true
    }
    
    override func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        NSLog("Ended editing row and index path")
        deleteEditing = false
    }
    
    // MARK: - UITableViewDatasource
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(10)
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        return view
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stockPlans.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return getSummaryCell(indexPath)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (expandedIndexPaths.filter({$0 == indexPath}).count != 0) {
            return SizeClass.getClassForSize().rowHeightExpanded
        } else {
            return SizeClass.getClassForSize().rowHeight
        }
    }
    
    func getSummaryCell(indexPath: NSIndexPath) -> UITableViewCell {
        let stockPlan = stockPlans[indexPath.row] as RestrictedOptionGrant
        let vestingResult = restrictedStockVestingCalulator.calculate(stockPlan)
        
        let summaryCell = tableView.dequeueReusableCellWithIdentifier(SummaryCellV2.REUSE_IDENTIFIER) as SummaryCellV2
        summaryCell.customize(stockPlan, vestingResult: vestingResult, indexPath: indexPath)
        summaryCell.cellDetailButtonPressedDelegate = self

        return summaryCell
    }
    
    func infoButtonPressed(cell: UITableViewCell) {
        if let indexPath = (cell as SummaryCellV2).indexPath {

            // indicate that a summary cell is updating
            summaryCellUpdating = true

            var expanding = false
            
            // check if the cell at indexPath is already expanded
            if (expandedIndexPaths.filter({$0 == indexPath}).count != 0) {
                // if its already expanded remove it so it can be contracted
                expandedIndexPaths = expandedIndexPaths.filter({$0 != indexPath})
                expanding = false
            } else {
                // if its not already expanded add it to the expanded list
                expandedIndexPaths.append(indexPath)
                expanding = true
            }
            
            // reload the row
            tableView.beginUpdates()
            
            // expand or contract the cell
            if (expanding) {
                (cell as SummaryCellV2).expandDetailView()
            } else {
                (cell as SummaryCellV2).contractDetailView()
            }
            
            tableView.endUpdates()
            
        } else {
            summaryCellUpdating = false
            NSLog("Cell has no index path, not displaying summary info")
        }
    }
    
    func detailButtonPressed(stockPlan: StockPlan?) {
        if (!deleteEditing) {
            if let plan = stockPlan {
                self.navigationController?.pushViewController(
                    RestrictedPlanDetailViewController(
                        restrictedOptionGrant: stockPlan as RestrictedOptionGrant, style: UITableViewStyle.Grouped),
                    animated: true
                )
            } else {
                NSLog("Cell has no associated stock plan, not displaying detail view")
            }
        } else {
            NSLog("Can not show details when editing")
        }
    }
}


























