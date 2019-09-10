//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

@objc
public protocol AttachmentApprovalViewControllerDelegate: class {
    func attachmentApproval(_ attachmentApproval: AttachmentApprovalViewController, didApproveAttachments attachments: [SignalAttachment], messageText: String?)
    func attachmentApproval(_ attachmentApproval: AttachmentApprovalViewController, didCancelAttachments attachments: [SignalAttachment])
}

struct SignalAttachmentItem: Hashable {
    let attachment: SignalAttachment
}

@objc
public class AttachmentApprovalViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, CaptioningToolbarDelegate {

    // MARK: Properties

    weak var approvalDelegate: AttachmentApprovalViewControllerDelegate?

    private(set) var captioningToolbar: CaptioningToolbar!

    // MARK: Initializers

    @available(*, unavailable, message:"use attachment: constructor instead.")
    required public init?(coder aDecoder: NSCoder) {
        notImplemented()
    }

    let kSpacingBetweenItems: CGFloat = 20

    @objc
    required public init(attachments: [SignalAttachment]) {
        assert(attachments.count > 0)
        self.attachmentItems = attachments.map { SignalAttachmentItem(attachment: $0 )}
        super.init(transitionStyle: .scroll,
                   navigationOrientation: .horizontal,
                   options: [UIPageViewControllerOptionInterPageSpacingKey: kSpacingBetweenItems])
        self.dataSource = self
        self.delegate = self
    }

    @objc
    public class func wrappedInNavController(attachments: [SignalAttachment], approvalDelegate: AttachmentApprovalViewControllerDelegate) -> OWSNavigationController {
        let vc = AttachmentApprovalViewController(attachments: attachments)
        vc.approvalDelegate = approvalDelegate
        let navController = OWSNavigationController(rootViewController: vc)

        guard let navigationBar = navController.navigationBar as? OWSNavigationBar else {
            owsFailDebug("navigationBar was nil or unexpected class")
            return navController
        }
        navigationBar.makeClear()

        return navController
    }

    // MARK: View Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .black

        disablePagingIfNecessary()

        // Bottom Toolbar

        let captioningToolbar = CaptioningToolbar()
        captioningToolbar.captioningToolbarDelegate = self
        self.captioningToolbar = captioningToolbar

        // Navigation

        self.navigationItem.title = nil

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(cancelPressed))
        cancelButton.tintColor = .white
        self.navigationItem.leftBarButtonItem = cancelButton

        guard let firstItem = attachmentItems.first else {
            owsFailDebug("firstItem was unexpectedly nil")
            return
        }

        self.setCurrentItem(firstItem, direction: .forward, animated: false)
    }

    override public func viewWillAppear(_ animated: Bool) {
        Logger.debug("")
        super.viewWillAppear(animated)

        CurrentAppContext().setStatusBarHidden(true, animated: animated)
    }

    override public func viewDidAppear(_ animated: Bool) {
        Logger.debug("")

        super.viewDidAppear(animated)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        Logger.debug("")
        super.viewWillDisappear(animated)

        // Since this VC is being dismissed, the "show status bar" animation would feel like
        // it's occuring on the presenting view controller - it's better not to animate at all.
        CurrentAppContext().setStatusBarHidden(false, animated: false)
    }

    override public var inputAccessoryView: UIView? {
        self.captioningToolbar.layoutIfNeeded()
        return self.captioningToolbar
    }

    override public var canBecomeFirstResponder: Bool {
        return true
    }

    // MARK: - View Helpers

    var pagerScrollView: UIScrollView?
    // This is kind of a hack. Since we don't have first class access to the superview's `scrollView`
    // we traverse the view hierarchy until we find it, then disable scrolling if there's only one
    // item. This avoids an unpleasant "bounce" which doesn't make sense in the context of a single item.
    fileprivate func disablePagingIfNecessary() {
        for view in self.view.subviews {
            if let pagerScrollView = view as? UIScrollView {
                self.pagerScrollView = pagerScrollView
                break
            }
        }

        guard let pagerScrollView = self.pagerScrollView else {
            owsFailDebug("pagerScrollView was unexpectedly nil")
            return
        }

        pagerScrollView.isScrollEnabled = attachmentItems.count > 1
    }

    // MARK: UIPageViewControllerDelegate

    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        Logger.debug("")

        assert(pendingViewControllers.count == 1)
        pendingViewControllers.forEach { viewController in
            guard let pendingPage = viewController as? AttachmentPrepViewController else {
                owsFailDebug("unexpected viewController: \(viewController)")
                return
            }

            // use compact scale when keyboard is popped.
            let scale: AttachmentPrepViewController.AttachmentViewScale = self.isFirstResponder ? .fullsize : .compact
            pendingPage.setAttachmentViewScale(scale, animated: false)
        }
    }

    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted: Bool) {
        Logger.debug("")

        assert(previousViewControllers.count == 1)
        previousViewControllers.forEach { viewController in
            guard let previousPage = viewController as? AttachmentPrepViewController else {
                owsFailDebug("unexpected viewController: \(viewController)")
                return
            }

            if transitionCompleted {
                UIView.transition(with: self.captioningToolbar,
                                  duration: 0.1,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.captioningToolbar.captionText = self.currentViewController.attachment.captionText
                },
                                  completion: nil)
                previousPage.zoomOut(animated: false)
            }
        }
    }

    // MARK: UIPageViewControllerDataSource

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentViewController = viewController as? AttachmentPrepViewController else {
            owsFailDebug("unexpected viewController: \(viewController)")
            return nil
        }

        let currentItem = currentViewController.attachmentItem
        guard let previousItem = attachmentItem(before: currentItem) else {
            return nil
        }

        guard let previousPage: AttachmentPrepViewController = buildPage(item: previousItem) else {
            return nil
        }

        return previousPage
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        Logger.debug("")

        guard let currentViewController = viewController as? AttachmentPrepViewController else {
            owsFailDebug("unexpected viewController: \(viewController)")
            return nil
        }

        let currentItem = currentViewController.attachmentItem
        guard let nextItem = attachmentItem(after: currentItem) else {
            return nil
        }

        guard let nextPage: AttachmentPrepViewController = buildPage(item: nextItem) else {
            return nil
        }

        return nextPage
    }

    public var currentViewController: AttachmentPrepViewController {
        return viewControllers!.first as! AttachmentPrepViewController
    }

    var currentItem: SignalAttachmentItem! {
        get {
            return currentViewController.attachmentItem
        }
        set {
            setCurrentItem(newValue, direction: .forward, animated: false)
        }
    }

    private var cachedPages: [SignalAttachmentItem: AttachmentPrepViewController] = [:]
    private func buildPage(item: SignalAttachmentItem) -> AttachmentPrepViewController? {

        if let cachedPage = cachedPages[item] {
            Logger.debug("cache hit.")
            return cachedPage
        }

        Logger.debug("cache miss.")
        let viewController = AttachmentPrepViewController(attachmentItem: item)
        cachedPages[item] = viewController

        return viewController
    }

    private func setCurrentItem(_ item: SignalAttachmentItem, direction: UIPageViewControllerNavigationDirection, animated isAnimated: Bool) {
        guard let page = self.buildPage(item: item) else {
            owsFailDebug("unexpetedly unable to build new page")
            return
        }

        self.setViewControllers([page], direction: direction, animated: isAnimated, completion: nil)
        // TODO update rail
    }

    let attachmentItems: [SignalAttachmentItem]
    var attachments: [SignalAttachment] {
        return attachmentItems.map { $0.attachment }
    }

    func attachmentItem(before currentItem: SignalAttachmentItem) -> SignalAttachmentItem? {
        guard let currentIndex = attachmentItems.index(of: currentItem) else {
            owsFailDebug("currentIndex was unexpectedly nil")
            return nil
        }

        let index: Int = attachmentItems.index(before: currentIndex)
        guard let previousItem = attachmentItems[safe: index] else {
            // already at first item
            return nil
        }

        return previousItem
    }

    func attachmentItem(after currentItem: SignalAttachmentItem) -> SignalAttachmentItem? {
        guard let currentIndex = attachmentItems.index(of: currentItem) else {
            owsFailDebug("currentIndex was unexpectedly nil")
            return nil
        }

        let index: Int = attachmentItems.index(after: currentIndex)
        guard let nextItem = attachmentItems[safe: index] else {
            // already at last item
            return nil
        }

        return nextItem
    }

    // MARK: - Event Handlers

    @objc func cancelPressed(sender: UIButton) {
        self.approvalDelegate?.attachmentApproval(self, didCancelAttachments: attachments)
    }

    // MARK: CaptioningToolbarDelegate

    var currentPageController: AttachmentPrepViewController {
        return viewControllers!.first as! AttachmentPrepViewController
    }

    func captioningToolbarDidBeginEditing(_ captioningToolbar: CaptioningToolbar) {
        currentPageController.setAttachmentViewScale(.compact, animated: true)
    }

    func captioningToolbarDidEndEditing(_ captioningToolbar: CaptioningToolbar) {
        currentPageController.setAttachmentViewScale(.fullsize, animated: true)
    }

    func captioningToolbarDidTapSend(_ captioningToolbar: CaptioningToolbar) {
        // Toolbar flickers in and out if there are errors
        // and remains visible momentarily after share extension is dismissed.
        // It's easiest to just hide it at this point since we're done with it.
        currentViewController.shouldAllowAttachmentViewResizing = false
        captioningToolbar.isUserInteractionEnabled = false
        captioningToolbar.isHidden = true

        approvalDelegate?.attachmentApproval(self, didApproveAttachments: attachments, messageText: captioningToolbar.captionText)
    }

    func captioningToolbar(_ captioningToolbar: CaptioningToolbar, textViewDidChange textView: UITextView) {
        // For 2.32.0 we only have one input bar - and it's for mesageBody text, not for caption text.
        // For 2.33.0 there are potentially two input bars - one for message body and one for caption text.
        // Commenting this out for now, but we'll have to resolve this merge conflict when RI'ing to 2.33
        // currentItem.attachment.captionText = textView.text
    }
}

public class AttachmentPrepViewController: OWSViewController, PlayerProgressBarDelegate, OWSVideoPlayerDelegate {
    // We sometimes shrink the attachment view so that it remains somewhat visible
    // when the keyboard is presented.
    enum AttachmentViewScale {
        case fullsize, compact
    }

    // MARK: Properties

    let attachmentItem: SignalAttachmentItem
    var attachment: SignalAttachment {
        return attachmentItem.attachment
    }

    private var videoPlayer: OWSVideoPlayer?

    private(set) var mediaMessageView: MediaMessageView!
    private(set) var scrollView: UIScrollView!
    private(set) var contentContainer: UIView!
    private(set) var playVideoButton: UIView?

    // MARK: Initializers

    init(attachmentItem: SignalAttachmentItem) {
        self.attachmentItem = attachmentItem
        super.init(nibName: nil, bundle: nil)
        assert(!attachment.hasError)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override public func loadView() {
        self.view = UIView()

        self.mediaMessageView = MediaMessageView(attachment: attachment, mode: .attachmentApproval)

        // Anything that should be shrunk when user pops keyboard lives in the contentContainer.
        let contentContainer = UIView()
        self.contentContainer = contentContainer
        view.addSubview(contentContainer)
        contentContainer.autoPinEdgesToSuperviewEdges()

        // Scroll View - used to zoom/pan on images and video
        scrollView = UIScrollView()
        contentContainer.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        // Panning should stop pretty soon after the user stops scrolling
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast

        // We want scroll view content up and behind the system status bar content
        // but we want other content (e.g. bar buttons) to respect the top layout guide.
        self.automaticallyAdjustsScrollViewInsets = false

        scrollView.autoPinEdgesToSuperviewEdges()

        let backgroundColor = UIColor.black
        self.view.backgroundColor = backgroundColor

        // Create full screen container view so the scrollView
        // can compute an appropriate content size in which to center
        // our media view.
        let containerView = UIView.container()
        scrollView.addSubview(containerView)
        containerView.autoPinEdgesToSuperviewEdges()
        containerView.autoMatch(.height, to: .height, of: self.view)
        containerView.autoMatch(.width, to: .width, of: self.view)

        containerView.addSubview(mediaMessageView)
        mediaMessageView.autoPinEdgesToSuperviewEdges()

        if isZoomable {
            // Add top and bottom gradients to ensure toolbar controls are legible
            // when placed over image/video preview which may be a clashing color.
            let topGradient = GradientView(from: backgroundColor, to: UIColor.clear)
            self.view.addSubview(topGradient)
            topGradient.autoPinWidthToSuperview()
            topGradient.autoPinEdge(toSuperviewEdge: .top)
            topGradient.autoSetDimension(.height, toSize: ScaleFromIPhone5(60))
        }

        // Hide the play button embedded in the MediaView and replace it with our own.
        // This allows us to zoom in on the media view without zooming in on the button
        if attachment.isVideo {

            guard let videoURL = attachment.dataUrl else {
                owsFailDebug("Missing videoURL")
                return
            }

            let player = OWSVideoPlayer(url: videoURL)
            self.videoPlayer = player
            player.delegate = self

            let playerView = VideoPlayerView()
            playerView.player = player.avPlayer
            self.mediaMessageView.addSubview(playerView)
            playerView.autoPinEdgesToSuperviewEdges()

            let pauseGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPlayerView(_:)))
            playerView.addGestureRecognizer(pauseGesture)

            let progressBar = PlayerProgressBar()
            progressBar.player = player.avPlayer
            progressBar.delegate = self

            // we don't want the progress bar to zoom during "pinch-to-zoom"
            // but we do want it to shrink with the media content when the user
            // pops the keyboard.
            contentContainer.addSubview(progressBar)

            progressBar.autoPin(toTopLayoutGuideOf: self, withInset: 0)
            progressBar.autoPinWidthToSuperview()
            progressBar.autoSetDimension(.height, toSize: 44)

            self.mediaMessageView.videoPlayButton?.isHidden = true
            let playButton = UIButton()
            self.playVideoButton = playButton
            playButton.accessibilityLabel = NSLocalizedString("PLAY_BUTTON_ACCESSABILITY_LABEL", comment: "Accessibility label for button to start media playback")
            playButton.setBackgroundImage(#imageLiteral(resourceName: "play_button"), for: .normal)
            playButton.contentMode = .scaleAspectFit

            let playButtonWidth = ScaleFromIPhone5(70)
            playButton.autoSetDimensions(to: CGSize(width: playButtonWidth, height: playButtonWidth))
            self.contentContainer.addSubview(playButton)

            playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
            playButton.autoCenterInSuperview()
        }
    }

    override public func viewWillLayoutSubviews() {
        Logger.debug("")
        super.viewWillLayoutSubviews()

        // e.g. if flipping to/from landscape
        updateMinZoomScaleForSize(view.bounds.size)

        ensureAttachmentViewScale(animated: false)
    }

    // MARK: 

    @objc public func didTapPlayerView(_ gestureRecognizer: UIGestureRecognizer) {
        assert(self.videoPlayer != nil)
        self.pauseVideo()
    }

    // MARK: - Event Handlers

    @objc
    public func playButtonTapped() {
        self.playVideo()
    }

    // MARK: Video

    private func playVideo() {
        Logger.info("")

        guard let videoPlayer = self.videoPlayer else {
            owsFailDebug("video player was unexpectedly nil")
            return
        }

        guard let playVideoButton = self.playVideoButton else {
            owsFailDebug("playVideoButton was unexpectedly nil")
            return
        }
        UIView.animate(withDuration: 0.1) {
            playVideoButton.alpha = 0.0
        }
        videoPlayer.play()
    }

    private func pauseVideo() {
        guard let videoPlayer = self.videoPlayer else {
            owsFailDebug("video player was unexpectedly nil")
            return
        }

        videoPlayer.pause()
        guard let playVideoButton = self.playVideoButton else {
            owsFailDebug("playVideoButton was unexpectedly nil")
            return
        }
        UIView.animate(withDuration: 0.1) {
            playVideoButton.alpha = 1.0
        }
    }

    @objc
    public func videoPlayerDidPlayToCompletion(_ videoPlayer: OWSVideoPlayer) {
        guard let playVideoButton = self.playVideoButton else {
            owsFailDebug("playVideoButton was unexpectedly nil")
            return
        }

        UIView.animate(withDuration: 0.1) {
            playVideoButton.alpha = 1.0
        }
    }

    public func playerProgressBarDidStartScrubbing(_ playerProgressBar: PlayerProgressBar) {
        guard let videoPlayer = self.videoPlayer else {
            owsFailDebug("video player was unexpectedly nil")
            return
        }
        videoPlayer.pause()
    }

    public func playerProgressBar(_ playerProgressBar: PlayerProgressBar, scrubbedToTime time: CMTime) {
        guard let videoPlayer = self.videoPlayer else {
            owsFailDebug("video player was unexpectedly nil")
            return
        }

        videoPlayer.seek(to: time)
    }

    public func playerProgressBar(_ playerProgressBar: PlayerProgressBar, didFinishScrubbingAtTime time: CMTime, shouldResumePlayback: Bool) {
        guard let videoPlayer = self.videoPlayer else {
            owsFailDebug("video player was unexpectedly nil")
            return
        }

        videoPlayer.seek(to: time)
        if (shouldResumePlayback) {
            videoPlayer.play()
        }
    }

    // MARK: Helpers

    var isZoomable: Bool {
        return attachment.isImage || attachment.isVideo
    }

    func zoomOut(animated: Bool) {
        if self.scrollView.zoomScale != self.scrollView.minimumZoomScale {
            self.scrollView.setZoomScale(self.scrollView.minimumZoomScale, animated: animated)
        }
    }

    // When the keyboard is popped, it can obscure the attachment view.
    // so we sometimes allow resizing the attachment.
    var shouldAllowAttachmentViewResizing: Bool = true

    var attachmentViewScale: AttachmentViewScale = .fullsize
    fileprivate func setAttachmentViewScale(_ attachmentViewScale: AttachmentViewScale, animated: Bool) {
        self.attachmentViewScale = attachmentViewScale
        ensureAttachmentViewScale(animated: animated)
    }

    func ensureAttachmentViewScale(animated: Bool) {
        let animationDuration = animated ? 0.2 : 0
        guard shouldAllowAttachmentViewResizing else {
            if self.contentContainer.transform != CGAffineTransform.identity {
                UIView.animate(withDuration: animationDuration) {
                    self.contentContainer.transform = CGAffineTransform.identity
                }
            }
            return
        }

        switch attachmentViewScale {
        case .fullsize:
            guard self.contentContainer.transform != .identity else {
                return
            }
            UIView.animate(withDuration: animationDuration) {
                self.contentContainer.transform = CGAffineTransform.identity
            }
        case .compact:
            guard self.contentContainer.transform == .identity else {
                return
            }
            UIView.animate(withDuration: animationDuration) {
                let kScaleFactor: CGFloat = 0.7
                let scale = CGAffineTransform(scaleX: kScaleFactor, y: kScaleFactor)

                let originalHeight = self.scrollView.bounds.size.height

                // Position the new scaled item to be centered with respect
                // to it's new size.
                let heightDelta = originalHeight * (1 - kScaleFactor)
                let translate = CGAffineTransform(translationX: 0, y: -heightDelta / 2)

                self.contentContainer.transform = scale.concatenating(translate)
            }
        }
    }
}

extension AttachmentPrepViewController: UIScrollViewDelegate {

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if isZoomable {
            return mediaMessageView
        } else {
            // don't zoom for audio or generic attachments.
            return nil
        }
    }

    fileprivate func updateMinZoomScaleForSize(_ size: CGSize) {
        Logger.debug("")

        // Ensure bounds have been computed
        mediaMessageView.layoutIfNeeded()
        guard mediaMessageView.bounds.width > 0, mediaMessageView.bounds.height > 0 else {
            Logger.warn("bad bounds")
            return
        }

        let widthScale = size.width / mediaMessageView.bounds.width
        let heightScale = size.height / mediaMessageView.bounds.height
        let minScale = min(widthScale, heightScale)
        scrollView.maximumZoomScale = minScale * 5.0
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }

    // Keep the media view centered within the scroll view as you zoom
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // The scroll view has zoomed, so you need to re-center the contents
        let scrollViewSize = self.scrollViewVisibleSize

        // First assume that mediaMessageView center coincides with the contents center
        // This is correct when the mediaMessageView is bigger than scrollView due to zoom
        var contentCenter = CGPoint(x: (scrollView.contentSize.width / 2), y: (scrollView.contentSize.height / 2))

        let scrollViewCenter = self.scrollViewCenter

        // if mediaMessageView is smaller than the scrollView visible size - fix the content center accordingly
        if self.scrollView.contentSize.width < scrollViewSize.width {
            contentCenter.x = scrollViewCenter.x
        }

        if self.scrollView.contentSize.height < scrollViewSize.height {
            contentCenter.y = scrollViewCenter.y
        }

        self.mediaMessageView.center = contentCenter
    }

    // return the scroll view center
    private var scrollViewCenter: CGPoint {
        let size = scrollViewVisibleSize
        return CGPoint(x: (size.width / 2), y: (size.height / 2))
    }

    // Return scrollview size without the area overlapping with tab and nav bar.
    private var scrollViewVisibleSize: CGSize {
        let contentInset = scrollView.contentInset
        let scrollViewSize = scrollView.bounds.standardized.size
        let width = scrollViewSize.width - (contentInset.left + contentInset.right)
        let height = scrollViewSize.height - (contentInset.top + contentInset.bottom)
        return CGSize(width: width, height: height)
    }
}

protocol CaptioningToolbarDelegate: class {
    func captioningToolbarDidTapSend(_ captioningToolbar: CaptioningToolbar)
    func captioningToolbarDidBeginEditing(_ captioningToolbar: CaptioningToolbar)
    func captioningToolbarDidEndEditing(_ captioningToolbar: CaptioningToolbar)
    func captioningToolbar(_ captioningToolbar: CaptioningToolbar, textViewDidChange: UITextView)
}

class CaptioningToolbar: UIView, UITextViewDelegate {

    weak var captioningToolbarDelegate: CaptioningToolbarDelegate?
    private let sendButton: UIButton
    private let textView: UITextView

    var captionText: String? {
        get { return self.textView.text }
        set { self.textView.text = newValue }
    }

    private let bottomGradient: GradientView
    private let lengthLimitLabel: UILabel

    // Layout Constants

    let kMinTextViewHeight: CGFloat = 38
    var maxTextViewHeight: CGFloat {
        // About ~4 lines in portrait and ~3 lines in landscape.
        // Otherwise we risk obscuring too much of the content.
        return UIDevice.current.orientation.isPortrait ? 160 : 100
    }
    var textViewHeightConstraint: NSLayoutConstraint!
    var textViewHeight: CGFloat

    class MessageTextView: UITextView {
        // When creating new lines, contentOffset is animated, but because because
        // we are simultaneously resizing the text view, this can cause the
        // text in the textview to be "too high" in the text view.
        // Solution is to disable animation for setting content offset.
        override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
            super.setContentOffset(contentOffset, animated: false)
        }
    }

    override var intrinsicContentSize: CGSize {
        get {
            // Since we have `self.autoresizingMask = UIViewAutoresizingFlexibleHeight`, we must specify
            // an intrinsicContentSize. Specifying CGSize.zero causes the height to be determined by autolayout.
            return CGSize.zero
        }
    }

    // MARK: Initializers

    init() {
        self.sendButton = UIButton(type: .system)
        self.bottomGradient = GradientView(from: UIColor.clear, to: UIColor.black)
        self.textView =  MessageTextView()
        self.textViewHeight = kMinTextViewHeight
        self.lengthLimitLabel = UILabel()

        super.init(frame: CGRect.zero)

        // Specifying autorsizing mask and an intrinsic content size allows proper
        // sizing when used as an input accessory view.
        self.autoresizingMask = .flexibleHeight
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor.clear

        textView.delegate = self
        textView.keyboardAppearance = Theme.keyboardAppearance
        textView.backgroundColor = (Theme.isDarkThemeEnabled ? UIColor.ows_gray90 : UIColor.ows_gray02)
        textView.layer.borderColor = (Theme.isDarkThemeEnabled
            ? Theme.primaryColor.withAlphaComponent(0.06).cgColor
            : Theme.primaryColor.withAlphaComponent(0.12).cgColor)
        textView.layer.borderWidth = 0.5
        textView.layer.cornerRadius = kMinTextViewHeight / 2

        textView.font = UIFont.ows_dynamicTypeBody
        textView.textColor = Theme.primaryColor
        textView.returnKeyType = .done
        textView.textContainerInset = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        textView.scrollIndicatorInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 3)

        let sendTitle = NSLocalizedString("ATTACHMENT_APPROVAL_SEND_BUTTON", comment: "Label for 'send' button in the 'attachment approval' dialog.")
        sendButton.setTitle(sendTitle, for: .normal)
        sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)

        sendButton.titleLabel?.font = UIFont.ows_mediumFont(withSize: 16)
        sendButton.titleLabel?.textAlignment = .center
        sendButton.tintColor = UIColor.white
        sendButton.backgroundColor = UIColor.ows_systemPrimaryButton
        sendButton.layer.cornerRadius = 4

        // Send Button Shadow - without this the send button bottom doesn't feel aligned with the toolbar.
        let kSendButtonShadowOffset: CGFloat = 1
        sendButton.layer.shadowColor = UIColor.darkGray.cgColor
        sendButton.layer.shadowOffset = CGSize(width: 0, height: kSendButtonShadowOffset)
        sendButton.layer.shadowOpacity = 0.8
        sendButton.layer.shadowRadius = 0.0
        sendButton.layer.masksToBounds = false

        // Increase hit area of send button
        sendButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)

        // Length Limit Label shown when the user inputs too long of a message
        lengthLimitLabel.textColor = .white
        lengthLimitLabel.text = NSLocalizedString("ATTACHMENT_APPROVAL_CAPTION_LENGTH_LIMIT_REACHED", comment: "One-line label indicating the user can add no more text to the attachment caption.")
        lengthLimitLabel.textAlignment = .center

        // Add shadow in case overlayed on white content
        lengthLimitLabel.layer.shadowColor = UIColor.black.cgColor
        lengthLimitLabel.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        lengthLimitLabel.layer.shadowOpacity = 0.8
        self.lengthLimitLabel.isHidden = true

        let contentView = UIView()
        addSubview(contentView)
        contentView.autoPinEdgesToSuperviewEdges()
        contentView.addSubview(bottomGradient)
        contentView.addSubview(sendButton)
        contentView.addSubview(textView)
        contentView.addSubview(lengthLimitLabel)

        // Layout
        let kToolbarMargin: CGFloat = 8

        // We have to wrap the toolbar items in a content view because iOS (at least on iOS10.3) assigns the inputAccessoryView.layoutMargins
        // when resigning first responder (verified by auditing with `layoutMarginsDidChange`).
        // The effect of this is that if we were to assign these margins to self.layoutMargins, they'd be blown away if the
        // user dismisses the keyboard, giving the input accessory view a wonky layout.
        contentView.layoutMargins = UIEdgeInsets(top: kToolbarMargin, left: kToolbarMargin, bottom: kToolbarMargin, right: kToolbarMargin)

        self.textViewHeightConstraint = textView.autoSetDimension(.height, toSize: kMinTextViewHeight)

        // We pin all three edges explicitly rather than doing something like:
        //  textView.autoPinEdges(toSuperviewMarginsExcludingEdge: .right)
        // because that method uses `leading` / `trailing` rather than `left` vs. `right`.
        // So it doesn't work as expected with RTL layouts when we explicitly want something
        // to be on the right side for both RTL and LTR layouts, like with the send button.
        // I believe this is a bug in PureLayout. Filed here: https://github.com/PureLayout/PureLayout/issues/209
        textView.autoPinEdge(toSuperviewMargin: .left)
        textView.autoPinEdge(toSuperviewMargin: .top)
        textView.autoPinEdge(toSuperviewMargin: .bottom)

        sendButton.autoPinEdge(.left, to: .right, of: textView, withOffset: kToolbarMargin)

        // Because the textview has a border, the sendButton feels unaligned without this shadow and offset
        sendButton.autoPinEdge(.bottom, to: .bottom, of: textView, withOffset: -kSendButtonShadowOffset)

        sendButton.autoPinEdge(toSuperviewMargin: .right)
        sendButton.setContentHuggingHigh()
        sendButton.setCompressionResistanceHigh()

        lengthLimitLabel.autoPinEdge(toSuperviewMargin: .left)
        lengthLimitLabel.autoPinEdge(toSuperviewMargin: .right)
        lengthLimitLabel.autoPinEdge(.bottom, to: .top, of: textView, withOffset: -6)
        lengthLimitLabel.setContentHuggingHigh()
        lengthLimitLabel.setCompressionResistanceHigh()

        let bottomGradientHeight = ScaleFromIPhone5(100)
        bottomGradient.autoSetDimension(.height, toSize: bottomGradientHeight)
        bottomGradient.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }

    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }

    // MARK: 

    @objc func didTapSend() {
        self.captioningToolbarDelegate?.captioningToolbarDidTapSend(self)
    }

    // MARK: - UITextViewDelegate

    public func textViewDidChange(_ textView: UITextView) {
        updateHeight(textView: textView)
        self.captioningToolbarDelegate?.captioningToolbar(self, textViewDidChange: textView)
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        let existingText: String = textView.text ?? ""
        let proposedText: String = (existingText as NSString).replacingCharacters(in: range, with: text)

        guard proposedText.utf8.count <= kOversizeTextMessageSizeThreshold else {
            Logger.debug("long text was truncated")
            self.lengthLimitLabel.isHidden = false

            // `range` represents the section of the existing text we will replace. We can re-use that space.
            // Range is in units of NSStrings's standard UTF-16 characters. Since some of those chars could be
            // represented as single bytes in utf-8, while others may be 8 or more, the only way to be sure is
            // to just measure the utf8 encoded bytes of the replaced substring.
            let bytesAfterDelete: Int = (existingText as NSString).replacingCharacters(in: range, with: "").utf8.count

            // Accept as much of the input as we can
            let byteBudget: Int = Int(kOversizeTextMessageSizeThreshold) - bytesAfterDelete
            if byteBudget >= 0, let acceptableNewText = text.truncated(toByteCount: UInt(byteBudget)) {
                textView.text = (existingText as NSString).replacingCharacters(in: range, with: acceptableNewText)
            }

            return false
        }
        self.lengthLimitLabel.isHidden = true

        // Though we can wrap the text, we don't want to encourage multline captions, plus a "done" button
        // allows the user to get the keyboard out of the way while in the attachment approval view.
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        } else {
            return true
        }
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        self.captioningToolbarDelegate?.captioningToolbarDidBeginEditing(self)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        self.captioningToolbarDelegate?.captioningToolbarDidEndEditing(self)
    }

    // MARK: - Helpers

    private func updateHeight(textView: UITextView) {
        // compute new height assuming width is unchanged
        let currentSize = textView.frame.size
        let newHeight = clampedTextViewHeight(fixedWidth: currentSize.width)

        if newHeight != self.textViewHeight {
            Logger.debug("TextView height changed: \(self.textViewHeight) -> \(newHeight)")
            self.textViewHeight = newHeight
            self.textViewHeightConstraint?.constant = textViewHeight
            self.invalidateIntrinsicContentSize()
        }
    }

    private func clampedTextViewHeight(fixedWidth: CGFloat) -> CGFloat {
        let contentSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        return CGFloatClamp(contentSize.height, kMinTextViewHeight, maxTextViewHeight)
    }
}
