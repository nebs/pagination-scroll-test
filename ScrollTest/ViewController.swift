import UIKit

class Message {
    let title: String
    let subtitle: String

    init(index: Int, subtitleCache: [String: String]) {
        title = "Message \(index)"

        if let cachedSubtitle = subtitleCache[title] {
            self.subtitle = cachedSubtitle
        } else {
            var randomText = ""
            for _ in 0...arc4random_uniform(50) {
                randomText += "Hello "
            }
            self.subtitle = randomText
        }
    }

    func text() -> String {
        return "\(title)\n\(subtitle)"
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    let simulatedLoadTimeSeconds: TimeInterval = 2
    let cellIdentifier = "message"
    let pageSize = 20
    var messageIndex = 0
    var messages = [Message]()
    var subtitleCache = [String: String]()
    var isLoading = false
    var lastContentOffsetY: CGFloat = 0 // Used to check scroll direction
    var cachedHeights = [IndexPath: CGFloat]()

    @discardableResult func generateMoreMessages() -> [IndexPath] {
        var indexPaths = [IndexPath]()
        for i in 0..<pageSize {
            let newMessage = Message(index: messageIndex, subtitleCache: subtitleCache)
            subtitleCache[newMessage.title] = newMessage.subtitle
            messages.insert(newMessage, at: 0)
            indexPaths.append(IndexPath(row: i, section: 0))
            messageIndex += 1
        }
        return indexPaths
    }

    func loadMoreMessages() {
        guard !isLoading else {
            return
        }

        let isFirstPage = messages.isEmpty
        isLoading = true
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + simulatedLoadTimeSeconds) {
            self.isLoading = false
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.reloadTableView()

            // Scroll to bottom on first load to simulate normal "chat" experience
            if isFirstPage {
                let bottomIndexPath = IndexPath(row: self.messages.count-1, section: 0)
                self.tableView.scrollToRow(at: bottomIndexPath, at: .bottom, animated: false)
            }
        }
    }

    func reloadTableView() {
        // ATTEMPT #1 - [ RELOAD DATA ]
        self.generateMoreMessages()
        self.tableView.reloadData()

        // ATTEMPT #2 - [ INSERT ROWS ]
//        let newIndexPaths = self.generateMoreMessages()
//        self.tableView.beginUpdates()
//        self.tableView.insertRows(at: newIndexPaths, with: .none)
//        self.tableView.endUpdates()

        // ATTEMPT #3 - [ RELOAD DATA AND SET CONTENT OFFSET ]
//        self.generateMoreMessages()
//        let offset = self.tableView.contentOffset
//        self.tableView.reloadData()
//        self.tableView.layoutIfNeeded()
//        self.tableView.contentOffset = offset

        // ATTEMPT #4 - [ RELOAD DATA AND REMEMBER SCROLL POSITION ]
//        var currentMessage: Message? = nil
//        if let topIndexPath = self.tableView.indexPathsForVisibleRows?.first { currentMessage = self.messages[topIndexPath.row] }
//        self.generateMoreMessages()
//        self.tableView.reloadData()
//        if let targetMessage = currentMessage,
//            let targetIndex = (self.messages.index{$0.title == targetMessage.title}) {
//            let targetIndexPath = IndexPath(row: targetIndex, section: 0)
//            self.tableView.scrollToRow(at: targetIndexPath, at: .top, animated: false)
//        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(MessageCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension;
        tableView.estimatedRowHeight = 88
        tableView.separatorStyle = .none;

        loadMoreMessages()
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.lastContentOffsetY > scrollView.contentOffset.y && scrollView.contentOffset.y < 100 {
            loadMoreMessages()
        }
        self.lastContentOffsetY = scrollView.contentOffset.y
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = messages[indexPath.row].text()
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cachedHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cachedHeights.removeValue(forKey: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = tableView.estimatedRowHeight
        if let cachedHeight = cachedHeights[indexPath] {
            height = cachedHeight
        }
        return height
    }
}
