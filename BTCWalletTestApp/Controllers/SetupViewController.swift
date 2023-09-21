//
//  SetupViewController.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 15.09.2023.
//

import UIKit
import Combine

enum SetupCellSection: String, CaseIterable {
    case selected = "Selected Words",
         available = "Available Words"
}

struct SetupCellItem: Hashable {
    let word: String
    let color: UIColor
}

final class SetupViewController: UICollectionViewController {
    class func instantiate(
        completionHandler: (() -> Void)? = nil
    ) -> UINavigationController {
        let viewController = SetupViewController
            .init(collectionViewLayout: UICollectionViewFlowLayout())
        viewController.modalPresentationStyle = .pageSheet
        viewController.isModalInPresentation = true
        viewController.title = "Setup"
        viewController.completionHandler = completionHandler
        
        return .init(rootViewController: viewController)
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<
        SetupCellSection,
        SetupCellItem
    >
    typealias Snapshot = NSDiffableDataSourceSnapshot<
        SetupCellSection,
        SetupCellItem
    >
    typealias Cell = WordCollectionViewCell
    typealias Header = WordCollectionViewHeaderView
    
    enum Section: CaseIterable {
        case selectedWords,
             availableWords
    }
    
    private var viewModel: SetupViewModelProtocol = SetupViewModel()
    private var dataSource: DataSource?
    private var viewModelToken: AnyCancellable?
    
    private var completionHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        configureCollectionView()
        configureDataSource()
        
        bindViewModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.input(.sync)
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        guard let word = dataSource?.itemIdentifier(for: indexPath)?.word else {
            return
        }
        viewModel.input(.didSelect(word))
    }
}

// MARK: - Selectors

@objc extension SetupViewController {
    func confirmSelection() {
        viewModel.input(.didConfirm)
    }
    
    func generateSelection() {
        viewModel.input(.didSelectGenerate)
    }
}

// MARK: - Private API

private extension SetupViewController {
    func configureNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Generate",
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(generateSelection))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Confirm",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(confirmSelection))
    }
    
    func configureCollectionView() {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 16.0,
                                                         left: 16.0,
                                                         bottom: 16.0,
                                                         right: 16.0)
        collectionViewLayout.headerReferenceSize = CGSize(width: collectionView.frame.size.width,
                                                          height: 44.0)
        
        collectionView.collectionViewLayout = collectionViewLayout
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsMultipleSelection = false
        collectionView.register(Cell.classForCoder(),
                                forCellWithReuseIdentifier: Cell.reuseIdentifier)
        collectionView.register(Header.classForCoder(),
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: Header.reuseIdentifier)
        
        collectionView.delegate = self
    }
    
    func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) {
            collectionView, indexPath, item in
            if let cell = collectionView
                .dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier,
                                     for: indexPath) as? Cell {
                cell.configure(with: item)
                
                return cell
            }
            return nil
        }
        
        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader,
                  let section = self.dataSource?.snapshot().sectionIdentifiers[indexPath.section],
                  let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                                   withReuseIdentifier: Header.reuseIdentifier,
                                                                                   for: indexPath) as? Header
            else {
                return UICollectionReusableView()
            }
            headerView.configure(with: section.rawValue.uppercased())
            
            return headerView
        }
    }
    
    func bindViewModel() {
        viewModelToken = viewModel.publisher
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case let .didUpdate(selected, available):
                    self.applySnapshot(selected: selected,
                                       available: available)
                case let .didFinish(phrase):
                    self.dismiss(animated: true) { [weak self] in
                        UserDefaults.standard.storedMnemonicPhrase = phrase
                        UserDefaults.standard.loggedIn = true
                        self?.completionHandler?()
                    }
                }
            }
    }
    
    func applySnapshot(selected: [String],
                       available: [String]) {
        var snapshot = Snapshot()
        let selectedItems: [SetupCellItem] = selected.map {
            .init(word: $0, color: viewModel.selectedState.color)
        }
        let availableItems: [SetupCellItem] = available.map {
            .init(word: $0, color: .tintColor)
        }
        
        snapshot.appendSections(SetupCellSection.allCases)
        snapshot.appendItems(selectedItems, toSection: .selected)
        snapshot.appendItems(availableItems, toSection: .available)
        
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Private extensions

private extension SetupViewModel.SelectionState {
    var color: UIColor {
        switch self {
        case .pending:
            return .tintColor
        case .complete:
            return .systemGreen
        case .error:
            return .systemRed
        }
    }
}
