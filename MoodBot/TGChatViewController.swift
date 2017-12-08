//
//  TGChatViewController.swift
//  MoodBot
//
//  Copyright (c) 2016-present, little2s.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import NoChat
import ApiAI
import UIKit
import MBProgressHUD

class TGChatViewController: NOCChatViewController, UINavigationControllerDelegate, MessageManagerDelegate, TGChatInputTextPanelDelegate, TGTextMessageCellDelegate {
    let initialized: Bool
    
    var titleView = TGTitleView()
    var avatarButton = TGAvatarButton()
    
    var messageManager = MessageManager.manager
    var layoutQueue = DispatchQueue(label: "com.little2s.nochat-example.tg.layout", qos: DispatchQoS(qosClass: .default, relativePriority: 0))

    let chat: Chat
    
    // MARK: Overrides
    
    override class func cellLayoutClass(forItemType type: String) -> Swift.AnyClass? {
        if type == "Text" {
            return TGTextMessageCellLayout.self
        } else if type == "Date" {
            return TGDateMessageCellLayout.self
        } else if type == "System" {
            return TGSystemMessageCellLayout.self
        } else {
            return nil
        }
    }
    
    override class func inputPanelClass() -> Swift.AnyClass? {
        return TGChatInputTextPanel.self
    }
    
    override func registerChatItemCells() {
        collectionView?.register(TGTextMessageCell.self, forCellWithReuseIdentifier: TGTextMessageCell.reuseIdentifier())
        collectionView?.register(TGDateMessageCell.self, forCellWithReuseIdentifier: TGDateMessageCell.reuseIdentifier())
        collectionView?.register(TGSystemMessageCell.self, forCellWithReuseIdentifier: TGSystemMessageCell.reuseIdentifier())
    }
    
    init(chat: Chat, initialized: Bool) {
        self.chat = chat
        self.initialized = initialized
        super.init(nibName: nil, bundle: nil)
        messageManager.addDelegate(self)
        registerContentSizeCategoryDidChangeNotification()
        setupNavigationItems()
        if(!initialized) {
            
            let request = ApiAI.shared().textRequest()
            request?.query = ["Welcome"]
            request?.setCompletionBlockSuccess({[unowned self] (request, response) -> Void in
                /**let resultNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ResultViewController") as! ResultNavigationController
                 
                 resultNavigationController.response = response as AnyObject?
                 
                 self.present(resultNavigationController, animated: true, completion: nil)
                 
                 hud.hide(animated: true)**/
                //let parsedData = try JSONSerialization.jsonObject(with: data!) as! [String:Any]
                //print(response!["result"]) // Any?
                
                //var json = JSONSerialization.toJson(response)
                let type = Mirror(reflecting: response!).subjectType
                print(type)
                
                let resp = response! as! NSDictionary
                let value = resp["result"]
                let valueNSDict = value! as! NSDictionary
                let valueNSDictValue = valueNSDict["fulfillment"]
                let fulfillment = valueNSDictValue! as! NSDictionary
                let messages = fulfillment["messages"] as! NSArray
                for item in messages {
                    
                    let msg = ((item as! NSDictionary)["speech"])!
                    //self.conversationView.text! += "Moodbot: " + (msg as! String) + "\n"
                    let message = Message()
                    message.text = (msg as! String)
                    self.receiveMessage(message)
                    /*let alert = UIAlertController(title: "Alert", message: msg as! String, preferredStyle: UIAlertControllerStyle.alert)
                     alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                     self.present(alert, animated: true, completion: nil)*/
                }
                //print(messages)
                
                //            do {
                //                if let json = try JSONSerialization.jsonObject(with: resp) as? [String:Any] {
                //                    print(json)
                //                }
                //            } catch let err{
                //                print(err.localizedDescription)
                //            }
                
                
                //hud.hide(animated: true)
                }, failure: { (request, error) -> Void in
                    // hud.hide(animated: true)
            });
            
            ApiAI.shared().enqueue(request)
        }
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        messageManager.removeDelegate(self)
        unregisterContentSizeCategoryDidChangeNotification()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //backgroundView?.image = UIImage(named: "TGWallpaper")!
        navigationController?.delegate = self
        ApiAI.shared().textRequest()
        loadMessages()
    }
    
    // MARK: TGChatInputTextPanelDelegate
    
    func inputTextPanel(_ inputTextPanel: TGChatInputTextPanel, requestSendText text: String) {
        let msg = Message()
        msg.text = text
        sendMessage(msg)
    }
    
    // MARK: TGTextMessageCellDelegate
    
    func didTapLink(cell: TGTextMessageCell, linkInfo: [AnyHashable: Any]) {
        inputPanel?.endInputting(true)
        
        guard let command = linkInfo["command"] as? String else { return }
        let msg = Message()
        msg.text = command
        sendMessage(msg)
    }
    
    // MARK: MessageManagerDelegate
    
    func didReceiveMessages(messages: [Message], chatId: String) {
        if isViewLoaded == false { return }
        
        if chatId == chat.chatId {
            addMessages(messages, scrollToBottom: true, animated: true)
            
            SoundManager.manager.playSound(name: "notification.caf", vibrate: false)
        }
    }
    
    // MARK: UINavigationControllerDelegate
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard viewController is ChatsViewController else {
            return
        }
        
        isInControllerTransition = true
        
        guard let tc = navigationController.topViewController?.transitionCoordinator else { return }
        tc.notifyWhenInteractionEnds { [weak self] (context) in
            guard let strongSelf = self else { return }
            if context.isCancelled {
                strongSelf.isInControllerTransition = false
            }
        }
    }
    
    // MARK: Private
    
    private func setupNavigationItems() {
        titleView.title = chat.title
        titleView.detail = chat.detail
        navigationItem.titleView = titleView
        
        let spacerItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacerItem.width = -12
        
        let rightItem = UIBarButtonItem(customView: avatarButton)
        
        navigationItem.rightBarButtonItems = [spacerItem, rightItem]
    }
    
    private func loadMessages() {
        layouts.removeAllObjects()
        
        messageManager.fetchMessages(withChatId: chat.chatId) { [weak self] (msgs) in
            if let strongSelf = self {
                strongSelf.addMessages(msgs, scrollToBottom: true, animated: false)
            }
        }
    }
    
    private func sendMessage(_ message: Message) {
        message.isOutgoing = true
        message.senderId = User.currentUser.userId
        //message.deliveryStatus = .Read
        
        addMessages([message], scrollToBottom: true, animated: true)
        
        messageManager.sendMessage(message, toChat: chat)
        
        SoundManager.manager.playSound(name: "sent.caf", vibrate: false)
        
        let hud = MBProgressHUD.showAdded(to: self.view.window!, animated: true)
        
       // self.textField?.resignFirstResponder()
        
        let request = ApiAI.shared().textRequest()
        
        let text = message.text
        if (text != ""){
            request?.query = [text]
            //conversationView.text! += "You: " + text + "\n"
            //self.textField?.text = ""
        } else {
            request?.query = [""]
        }
        
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            if response.result.action == "money" {
                if let parameters = response.result.parameters as? [String: AIResponseParameter]{
                    let amount = parameters["amout"]!.stringValue
                    let currency = parameters["currency"]!.stringValue
                    let date = parameters["date"]!.dateValue
                    
                    print("Spended \(amount) of \(currency) on \(date)")
                }
            }
        }, failure: { (request, error) in
            // TODO: handle error
        })
        
        request?.setCompletionBlockSuccess({[unowned self] (request, response) -> Void in
            /**let resultNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ResultViewController") as! ResultNavigationController
             
             resultNavigationController.response = response as AnyObject?
             
             self.present(resultNavigationController, animated: true, completion: nil)
             
             hud.hide(animated: true)**/
            //let parsedData = try JSONSerialization.jsonObject(with: data!) as! [String:Any]
            //print(response!["result"]) // Any?
            
            //var json = JSONSerialization.toJson(response)
            let type = Mirror(reflecting: response!).subjectType
            print(type)
            
            let resp = response! as! NSDictionary
            let value = resp["result"]
            let valueNSDict = value! as! NSDictionary
            let valueNSDictValue = valueNSDict["fulfillment"]
            let fulfillment = valueNSDictValue! as! NSDictionary
            let messages = fulfillment["messages"] as! NSArray
            for item in messages {
                
                let msg = ((item as! NSDictionary)["speech"])!
                //self.conversationView.text! += "Moodbot: " + (msg as! String) + "\n"
                let message = Message()
                message.text = (msg as! String)
                self.receiveMessage(message)
                /*let alert = UIAlertController(title: "Alert", message: msg as! String, preferredStyle: UIAlertControllerStyle.alert)
                 alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                 self.present(alert, animated: true, completion: nil)*/
            }
            //print(messages)
            
            //            do {
            //                if let json = try JSONSerialization.jsonObject(with: resp) as? [String:Any] {
            //                    print(json)
            //                }
            //            } catch let err{
            //                print(err.localizedDescription)
            //            }
            
            
            hud.hide(animated: true)
            }, failure: { (request, error) -> Void in
                hud.hide(animated: true)
        });
        
        ApiAI.shared().enqueue(request)
        
    }
    
    private func receiveMessage(_ message: Message) {
        message.isOutgoing = false
        message.senderId = User.currentUser.userId
        //message.deliveryStatus = .Read
        
        addMessages([message], scrollToBottom: true, animated: true)
        
        messageManager.sendMessage(message, toChat: chat)
        
        SoundManager.manager.playSound(name: "notification.caf", vibrate: false)
    }
    
    private func addMessages(_ messages: [Message], scrollToBottom: Bool, animated: Bool) {
        layoutQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            let indexes = IndexSet(integersIn: 0..<messages.count)
            
            var layouts = [NOCChatItemCellLayout]()
            
            for message in messages {
                //message.text = "blahhh"
                let layout = strongSelf.createLayout(with: message)!
                layouts.insert(layout, at: 0)
            }
            
            DispatchQueue.main.async {
                strongSelf.insertLayouts(layouts, at: indexes, animated: animated)
                if scrollToBottom {
                    strongSelf.scrollToBottom(animated: animated)
                }
            }
        }
    }
    
    // MARK: Dynamic font support
    
    private func registerContentSizeCategoryDidChangeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleContentSizeCategoryDidChanged(notification:)), name: .UIContentSizeCategoryDidChange, object: nil)
    }
    
    private func unregisterContentSizeCategoryDidChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .UIContentSizeCategoryDidChange, object: nil)
    }
    
    @objc private func handleContentSizeCategoryDidChanged(notification: Notification) {
        if isViewLoaded == false {
            return
        }
        
        if layouts.count == 0 {
            return
        }
        
        // ajust collection display
        
        let collectionViewSize = containerView!.bounds.size
        
        let anchorItem = calculateAnchorItem()
        
        for layout in layouts {
            (layout as! NOCChatItemCellLayout).calculate()
        }
        
        collectionLayout!.invalidateLayout()
        
        let cellLayouts = layouts.map { $0 as! NOCChatItemCellLayout }
        
        var newContentHeight = CGFloat(0)
        let newLayoutAttributes = collectionLayout!.layoutAttributes(for: cellLayouts, containerWidth: collectionViewSize.width, maxHeight: CGFloat.greatestFiniteMagnitude, contentHeight: &newContentHeight)
        
        var newContentOffset = CGPoint.zero
        newContentOffset.y = -collectionView!.contentInset.top
        if anchorItem.index >= 0 && anchorItem.index < newLayoutAttributes.count {
            let attributes = newLayoutAttributes[anchorItem.index]
            newContentOffset.y += attributes.frame.origin.y - floor(anchorItem.offset * attributes.frame.height)
        }
        newContentOffset.y = min(newContentOffset.y, newContentHeight + collectionView!.contentInset.bottom - collectionView!.frame.height)
        newContentOffset.y = max(newContentOffset.y, -collectionView!.contentInset.top)
        
        collectionView!.reloadData()
        
        collectionView!.contentOffset = newContentOffset
        
        // fix navigation items display
        setupNavigationItems()
    }
    
    typealias AnchorItem = (index: Int, originY: CGFloat, offset: CGFloat, height: CGFloat)
    private func calculateAnchorItem() -> AnchorItem {
        let maxOriginY = collectionView!.contentOffset.y + collectionView!.contentInset.top
        let previousCollectionFrame = collectionView!.frame
        
        var itemIndex = Int(-1)
        var itemOriginY = CGFloat(0)
        var itemOffset = CGFloat(0)
        var itemHeight = CGFloat(0)
        
        let cellLayouts = layouts.map { $0 as! NOCChatItemCellLayout }

        let previousLayoutAttributes = collectionLayout!.layoutAttributes(for: cellLayouts, containerWidth: previousCollectionFrame.width, maxHeight: CGFloat.greatestFiniteMagnitude, contentHeight: nil)
        
        for i in 0..<layouts.count {
            let attributes = previousLayoutAttributes[i]
            let itemFrame = attributes.frame
            
            if itemFrame.origin.y < maxOriginY {
                itemHeight = itemFrame.height
                itemIndex = i
                itemOriginY = itemFrame.origin.y
            }
        }
        
        if itemIndex != -1 {
            if itemHeight > 1 {
                itemOffset = (itemOriginY - maxOriginY) / itemHeight
            }
        }
        
        return (itemIndex, itemOriginY, itemOffset, itemHeight)
    }
    
}


