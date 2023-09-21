//
//  RootViewController.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 15.09.2023.
//

import UIKit
import Combine

final class RootViewController: UITableViewController {
    class func instantiate() -> UINavigationController {
        let viewController = RootViewController(style: .insetGrouped)
        viewController.title = "BTC Waller Test App"
        
        let navigationController = UINavigationController(rootViewController: viewController)
        
        return navigationController
    }
    
    typealias DataSource = UITableViewDiffableDataSource<
        RootViewController.Section,
        RootViewController.Item
    >
    typealias Snapshot = NSDiffableDataSourceSnapshot<
        RootViewController.Section,
        RootViewController.Item
    >
    typealias TitleWithActionCell = TitleWithActionTableViewCell
    typealias BalanceCell = BalanceTableViewCell
    typealias SyncStateCell = SyncStateTableViewCell
    typealias AddressCell = AddressTableViewCell
    typealias SendAddressCell = SendAddressTableViewCell
    typealias SendAmountCell = SendAmountTableViewCell
    typealias SendButtonCell = SendButtonTableViewCell
    typealias TransactionCell = TransactionTableViewCell
    
    enum Section {
        case balance,
             syncState,
             address,
             send,
             transaction
    }
    
    enum Item: Hashable {
        case title(_ configured: TitleWithActionCell.Configuration),
             balance(_ value: String),
             address(_ value: String),
             syncState(_ configured: SyncStateCell.Configuration),
             sendAddress(_ value: String?),
             sendAmount(_ value: String?),
             sendButton,
             transaction(_ transaction: LastTransaction?)
    }
    
    private let viewModel: RootVieweModelProtocol = RootViewModel()
    private var dataSource: DataSource?
    
    private var viewModelToken: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationController()
        configureTableView()
        configureDataSource()
        
        registerCells()
        
        bindViewModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.input(.sync)
    }
}

// MARK: - Selectors

@objc extension RootViewController {
    func logout() {
        viewModel.input(.logout)
    }
}

// MARK: - Private API

private extension RootViewController {
    func configureNavigationController() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(logout))
        navigationItem.rightBarButtonItem?.tintColor = .systemRed
    }
    
    func configureTableView() {
        tableView.automaticallyAdjustsScrollIndicatorInsets = false
        tableView.allowsSelection = false
        tableView.alwaysBounceVertical = false
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
    }
    
    func registerCells() {
        tableView.register(TitleWithActionCell.self,
                           forCellReuseIdentifier: TitleWithActionCell.reuseIdentifier)
        tableView.register(BalanceCell.self,
                           forCellReuseIdentifier: BalanceCell.reuseIdentifier)
        tableView.register(SyncStateCell.self,
                           forCellReuseIdentifier: SyncStateCell.reuseIdentifier)
        tableView.register(AddressCell.self,
                           forCellReuseIdentifier: AddressCell.reuseIdentifier)
        tableView.register(SendAddressCell.self,
                           forCellReuseIdentifier: SendAddressCell.reuseIdentifier)
        tableView.register(SendAmountCell.self,
                           forCellReuseIdentifier: SendAmountCell.reuseIdentifier)
        tableView.register(SendButtonCell.self,
                           forCellReuseIdentifier: SendButtonCell.reuseIdentifier)
        tableView.register(TransactionCell.self,
                           forCellReuseIdentifier: TransactionCell.reuseIdentifier)
        
    }
    
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) {
            [unowned self] tableView, indexPath, item in
            switch item {
            case let .title(configuration):
                if let cell = tableView.dequeueReusableCell(withIdentifier: TitleWithActionCell.reuseIdentifier,
                                                            for: indexPath) as? TitleWithActionCell {
                    cell.configured(as: configuration) { [unowned self] in
                        switch configuration {
                        case .address:
                            copyAddressToClipboard()
                        case .balance:
                            viewModel.input(.refresh)
                        case .send:
                            viewModel.input(.clearStoredSendData)
                        default:
                            break
                        }
                    }
                    
                    return cell
                }
            case let .balance(value):
                if let cell = tableView.dequeueReusableCell(withIdentifier: BalanceCell.reuseIdentifier,
                                                            for: indexPath) as? BalanceCell {
                    cell.configure(value)
                    
                    return cell
                }
            case let .address(value):
                if let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.reuseIdentifier,
                                                            for: indexPath) as? AddressCell {
                    cell.configure(value)
                    
                    return cell
                }
            case let .syncState(configuration):
                if let cell = tableView.dequeueReusableCell(withIdentifier: SyncStateCell.reuseIdentifier,
                                                            for: indexPath) as? SyncStateCell {
                    cell.configured(as: configuration)
                    
                    return cell
                }
            case let .sendAddress(text):
                if let cell = tableView.dequeueReusableCell(withIdentifier: SendAddressCell.reuseIdentifier,
                                                            for: indexPath) as? SendAddressCell {
                    cell.configure(address: text,
                                   validationPublisher: viewModel.addressPubliher)
                    viewModel.bind(address: cell)
                    
                    return cell
                }
            case let .sendAmount(amount):
                if let cell = tableView.dequeueReusableCell(withIdentifier: SendAmountCell.reuseIdentifier,
                                                            for: indexPath) as? SendAmountCell {
                    cell.configure(amount: amount,
                                   validationPublisher: viewModel.amountPublisher)
                    viewModel.bind(amount: cell)
                    
                    return cell
                }
            case .sendButton:
                if let cell = tableView.dequeueReusableCell(withIdentifier: SendButtonCell.reuseIdentifier,
                                                            for: indexPath) as? SendButtonCell {
                    cell.callback = { [unowned self] in
                        view.endEditing(true)
                        viewModel.input(.send)
                    }
                    
                    return cell
                }
            case let .transaction(transaction):
                if let cell = tableView.dequeueReusableCell(withIdentifier: TransactionCell.reuseIdentifier,
                                                            for: indexPath) as? TransactionCell {
                    cell.configure(with: transaction)
                    
                    return cell
                }
            }
            
            return nil
        }
        
        dataSource?.defaultRowAnimation = .fade
    }
    
    func bindViewModel() {
        viewModelToken = viewModel.output
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] event in
                switch event {
                case .loginRequired:
                    applySnapshot()
                    showLogin()
                case let .refresh(reloadData):
                    applySnapshot(reloadData: reloadData)
                    viewModel.input(.refreshValidation)
                case let .transactionSuccess(hash):
                    showSuccess(hash: hash)
                case let .transactionError(message):
                    showError(message: message)
                }
            }
    }
    
    func showLogin() {
        let viewController = SetupViewController.instantiate { [unowned self] in
            viewModel.input(.login)
        }
        
        present(viewController, animated: true)
    }
    
    func applySnapshot(reloadData: Bool = false) {
        var snapshot = Snapshot()
        
        let sections = viewModel.sections
        
        snapshot.appendSections(sections)
        
        for section in sections {
            let items = viewModel.items(for: section)
            snapshot.appendItems(items, toSection: section)
        }
        
        if reloadData {
            dataSource?.applySnapshotUsingReloadData(snapshot)
            return
        }
        
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    func showSuccess(hash: String) {
        showAlert(with: "Success!",
                  message: "Transaction # \(hash)") { [unowned self] in
            applySnapshot(reloadData: true)
        }
    }
    
    func showError(message: String) {
        showAlert(with: "Error!", message: message)
    }
    
    func showAlert(with title: String,
                   message: String,
                   completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(.init(title: "OK", style: .default) { _ in
            completion?()
        })
        
        present(alertController, animated: true)
    }
    
    func copyAddressToClipboard() {
        guard let address = viewModel.address, !address.isEmpty else { return }
        copyToClipboard(address)
    }
    
    func copyToClipboard(_ string: String) {
        UIPasteboard.general.string = string
    }
}
