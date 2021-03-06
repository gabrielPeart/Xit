import Foundation

/// Abstract base class for file list data sources.
class FileListDataSourceBase: NSObject
{
  @IBOutlet weak var outlineView: NSOutlineView!
  @IBOutlet weak var controller: FileViewController!
  
  let observers = ObserverCollection()
  
  struct ColumnID
  {
    static let unstaged = NSUserInterfaceItemIdentifier(rawValue: "unstaged")
  }
  
  weak var taskQueue: TaskQueue?
  weak var repoController: RepositoryController!
  {
    didSet
    {
      observers.addObserver(forName: .XTSelectedModelChanged,
                            object: repoController, queue: .main) {
        [weak self] (_) in
        guard let myself = self,
              myself.outlineView?.dataSource === myself,
              myself.repoController != nil // Otherwise we're on a stale timer
        else { return }
        
        (myself as? FileListDataSource)?.reload()
        myself.updateStagingView()
      }
    }
  }
  
  class func transformDisplayChange(_ change: DeltaStatus) -> DeltaStatus
  {
    return (change == .unmodified) ? .mixed : change
  }
  
  func observe(repository: AnyObject)
  {
    (self as! FileListDataSource).reload()
    observers.addObserver(forName: .XTRepositoryWorkspaceChanged,
                          object: repository, queue: .main) {
      [weak self] (note) in
      guard let myself = self
      else { return }
      
      if myself.outlineView?.dataSource === myself {
        myself.workspaceChanged(note.userInfo?[XTPathsKey] as? [String])
      }
    }
  }
  
  func workspaceChanged(_ paths: [String]?)
  {
    if repoController.selectedModel is StagingChanges {
      (self as! FileListDataSource).reload()
    }
  }
  
  func updateStagingView()
  {
    let unstagedColumn = outlineView.tableColumn(withIdentifier: ColumnID.unstaged)
    
    unstagedColumn?.isHidden = !(repoController.selectedModel?.hasUnstaged
                                 ?? false)
  }
}


/// Methods that a file list data source must implement.
protocol FileListDataSource: class
{
  var hierarchical: Bool { get }
  
  func reload()
  func fileChange(at row: Int) -> FileChange?
  func path(for item: Any) -> String
  func change(for item: Any) -> DeltaStatus
  func unstagedChange(for item: Any) -> DeltaStatus
}


/// Cell view with custom drawing for deleted files.
class FileCellView: NSTableCellView
{
  /// The change is stored to improve drawing of selected deleted files.
  var change: DeltaStatus = .unmodified
  
  override var backgroundStyle: NSView.BackgroundStyle
  {
    didSet
    {
      if backgroundStyle == .dark {
        textField?.textColor = .textColor
      }
      else if change == .deleted {
        textField?.textColor = .disabledControlTextColor
      }
    }
  }
}


/// Cell view with a button rather than an image.
class TableButtonView: NSTableCellView
{
  @IBOutlet var button: NSButton!
}
