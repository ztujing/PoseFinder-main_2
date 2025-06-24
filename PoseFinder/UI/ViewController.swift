/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The implementation of the application's view controller, responsible for coordinating
 the user interface, video feed, and PoseNet model.
 */

import AVFoundation
import UIKit
import VideoToolbox
// 追加
import MLKitPoseDetection
import MLKitVision

extension CIImage {
    func toCGImage() -> CGImage? {
        let context = { CIContext(options: nil) }()
        return context.createCGImage(self, from: self.extent)
    }
}
final class TeacherStudentRatio {
    // インスタンスを参照するためのプロパティ
    static let shared = TeacherStudentRatio ()
    
    // ここに変数を列挙するはじめは0を入れておいてよい。
    var originToRightShoulder = 1.0;
    var rightShoulderToRightElbow = 1.0;
    var rightElbowToRightWrist = 1.0;
    var originToRightHip = 1.0;
    var rightHipToRightKnee = 1.0;
    var rightKneeToRightAnkle = 1.0;
    var midpointOfShouldersToRightEar = 1.0;
    var originToLeftShoulder = 1.0;
    var leftShoulderToLeftElbow = 1.0;
    var leftElbowToLeftWrist = 1.0;
    var originToLeftHip = 1.0;
    var leftHipToLeftKnee = 1.0;
    var leftKneeToLeftAnkle = 1.0;
    var midpointOfShouldersToLeftEar = 1.0;
    
    
    // イニシャライズ
    private init() {
        // 今回は定数を代入する。いずれは、ローカルのDBかファイルに保存しておいて読み込むようにする。
        //      self.originToRightShoulder = 0.9042862676;
        //      self.rightShoulderToRightElbow = 1.245541657;
        //      self.rightElbowToRightWrist = 0.8226015546;
        //      self.originToRightHip = 0.9789301811;
        //      self.rightHipToRightKnee = 1.253915664;
        //      self.rightKneeToRightAnkle = 1.247329766;
        //      self.midpointOfShouldersToRightEar = 0.8929083536;
        //      self.originToLeftShoulder = 0.9518434667;
        //      self.leftShoulderToLeftElbow = 1.094948532;
        //      self.leftElbowToLeftWrist = 1.165524656;
        //      self.originToLeftHip = 0.9649565827;
        //      self.leftHipToLeftKnee = 1.168294556;
        //      self.leftKneeToLeftAnkle = 1.185906149;
        //      self.midpointOfShouldersToLeftEar = 0.8855039207;
        
        
        
    }
    public static func getInstance() -> TeacherStudentRatio {
        return shared;
    }
    //    public func getScaledPoses(pose: Pose) -> Pose {
    //
    //    }
}
class ViewController: UIViewController {
    /// The view the controller uses to visualize the detected poses.
    @IBOutlet private var videoPreviewImageView: PoseImageView!
    @IBOutlet private var moviePreviewImageView: PoseImageView!
    @IBOutlet private var movieScaledPreviewImageView: PoseImageView!
    
    @IBOutlet weak var ScoreLabel: UILabel!
    private let videoCapture = VideoCapture()
    
    //    private var videoPoseNet: PoseNet!
    //    private var moviePoseNet: PoseNet!
    
    // 変更
    private var videoPoseDetector: PoseDetector!
    private var moviePoseDetector: PoseDetector!
    
    /// The frame the PoseNet model is currently making pose predictions from.
    private var videoCurrentFrame: CGImage?
    private var movieCurrentFrame: CGImage?
    
    /// The algorithm the controller uses to extract poses from the current frame.
    private var algorithm: Algorithm = .single
    
    /// The set of parameters passed to the pose builder when detecting poses.
    private var poseBuilderConfiguration = PoseBuilderConfiguration()
    
    private var popOverPresentationManager: PopOverPresentationManager?
    
    private var playerLayer:AVPlayerLayer!
    private var player:AVPlayer!
    @IBOutlet weak var playerView: PlayerView!
    
    //teacherScaledPoseプロパティを追加
    var teacherPose: Pose = Pose()
    private var sessionDirectory: URL?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セッションディレクトリ作成
        guard let dir = createSessionDirectory() else {
            fatalError("セッションディレクトリの作成に失敗しました")
        }
        sessionDirectory = dir
        
        // For convenience, the idle timer is disabled to prevent the screen from locking.
        UIApplication.shared.isIdleTimerDisabled = true
        
        //      do {
        //          videoPoseNet = try PoseNet(type: "video")
        //          moviePoseNet = try PoseNet(type: "movie")
        //
        //      } catch {
        //        fatalError("Failed to load model. \(error.localizedDescription)")
        //      }
        
        //      videoPoseNet.delegate = self
        //      moviePoseNet.delegate = self
        
        // 追加
        setupPoseDetectors()
        setupAndBeginCapturingVideoFrames()
        setupAndBeginCapturingMovieFrames()
    }
    
    //追加　Viewのサイズを揃える
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        videoPreviewImageView.frame = view.bounds
        movieScaledPreviewImageView.frame = view.bounds
    }
    
    // 追加
    private func setupPoseDetectors(){
        let options = PoseDetectorOptions()
        options.detectorMode = .stream
        
        videoPoseDetector = PoseDetector.poseDetector(options: options)
        moviePoseDetector = PoseDetector.poseDetector(options: options)
        
    }
    
    private func setupAndBeginCapturingMovieFrames() {
        let asset = AVAsset(url: Bundle.main.url(forResource: "traning", withExtension: "mp4")!)
        let composition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { [self] request in
            //          print("test")
            //          let source = request.sourceImage.clampedToExtent()
            
            let source = request.sourceImage
            guard let cgImage = source.toCGImage() else {
                return
            }
            // CGImage to UIImage
            let uiImage = UIImage(cgImage: cgImage)
            
            //            moviePreviewImageView.image = uiImage
            
            defer {
                request.finish(with: request.sourceImage, context: nil)
            }
            
            guard self.movieCurrentFrame == nil else {
                return
            }
            
            //コマ落ちしても良い
            
            self.movieCurrentFrame = cgImage
            
            
            // UIImage to VisionImage
            let visionImage = VisionImage(image: uiImage)
            
            // ポーズ検出処理
            self.moviePoseDetector.process(visionImage) {detectedPoses, error in
                guard error == nil else {
                    self.movieCurrentFrame = nil
                    // Error.
                    return
                }
                guard let poses = detectedPoses, !poses.isEmpty else {
                    self.movieCurrentFrame = nil
                    // No pose detected.
                    return
                }
                guard let currentFrame = movieCurrentFrame else {
                    return
                }
                var pose = poses[0]
                // 3. PoseBuilderV2 を初期化して、内部の Pose オブジェクトを構築する
                let builder = PoseBuilderV2(mlKitPose: pose, configuration: self.poseBuilderConfiguration)
                
                // 先生のポーズ
                
                self.teacherPose = builder.pose
                
                // moviePreviewImageView.show の呼び出しを修正
                self.moviePreviewImageView.show(scaledPose: self.teacherPose, studentPose: self.teacherPose, on: currentFrame, isFrameDraw: true)
                
                self.movieCurrentFrame = nil
            }
        }
                                             
        )
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.videoComposition = composition
        
        self.player = AVPlayer(playerItem: playerItem)
        
        self.playerLayer = AVPlayerLayer(player: player)
        // 表示モードの設定
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        playerLayer.contentsScale = UIScreen.main.scale
        
        self.playerView.playerLayer = self.playerLayer
        self.playerView.layer.insertSublayer(playerLayer, at: 0)
        
        self.player.play()
        
        
        
    }
    private func setupAndBeginCapturingVideoFrames() {
        videoCapture.setUpAVCapture { error in
            if let error = error {
                print("Failed to setup camera with error \(error)")
                return
            }
            
            self.videoCapture.delegate = self
            
            self.videoCapture.startCapturing()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        videoCapture.stopCapturing {
            super.viewWillDisappear(animated)
        }
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        // Reinitilize the camera to update its output stream with the new orientation.
        setupAndBeginCapturingVideoFrames()
    }
    
    @IBAction func onCameraButtonTapped(_ sender: Any) {
        videoCapture.flipCamera { error in
            if let error = error {
                print("Failed to flip camera with error \(error)")
            }
        }
    }
    
    @IBAction func onAlgorithmSegmentValueChanged(_ sender: UISegmentedControl) {
        guard let selectedAlgorithm = Algorithm(
            rawValue: sender.selectedSegmentIndex) else {
            return
        }
        
        algorithm = selectedAlgorithm
    }
}

// MARK: - Navigation

extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let uiNavigationController = segue.destination as? UINavigationController else {
            return
        }
        guard let configurationViewController = uiNavigationController.viewControllers.first
                as? ConfigurationViewController else {
            return
        }
        
        configurationViewController.configuration = poseBuilderConfiguration
        configurationViewController.algorithm = algorithm
        configurationViewController.delegate = self
        
        popOverPresentationManager = PopOverPresentationManager(presenting: self,
                                                                presented: uiNavigationController)
        segue.destination.modalPresentationStyle = .custom
        segue.destination.transitioningDelegate = popOverPresentationManager
    }
}

// MARK: - ConfigurationViewControllerDelegate

extension ViewController: ConfigurationViewControllerDelegate {
    func configurationViewController(_ viewController: ConfigurationViewController,
                                     didUpdateConfiguration configuration: PoseBuilderConfiguration) {
        poseBuilderConfiguration = configuration
    }
    
    func configurationViewController(_ viewController: ConfigurationViewController,
                                     didUpdateAlgorithm algorithm: Algorithm) {
        self.algorithm = algorithm
    }
}

// MARK: - VideoCaptureDelegate

extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame capturedImage: CGImage?) {
        
        guard let image = capturedImage else {
            fatalError("Captured image is null")
        }
        
        //CGImage to UIImage
        let uiImage = UIImage(cgImage: image)
        
        self.videoPreviewImageView.image = uiImage
        
        
        guard videoCurrentFrame == nil else {
            return
        }
        
        self.videoCurrentFrame = image
        
        //UIImage to VisionImage
        let visionImage = VisionImage(image: uiImage)
        
        // ポーズ検出処理
        videoPoseDetector.process(visionImage) { detectedPoses, error in
            guard error == nil else {
                self.videoCurrentFrame = nil
                // Error.
                print("error in video")
                return
            }
            guard let currentFrame = self.videoCurrentFrame else {
                return
            }
            guard let poses = detectedPoses, !poses.isEmpty else {
                self.videoCurrentFrame = nil
                // No pose detected.
                print("no pose in video")
                return
            }
            
            // Success. Get pose landmarks here.
            var pose = poses[0]
            // 3. PoseBuilderV2 を初期化して、内部の Pose オブジェクトを構築する
            let builder = PoseBuilderV2(mlKitPose: pose, configuration: self.poseBuilderConfiguration)
            
            let studentPose = builder.pose
            
            let scaledPoseHelper = ScaledPoseHelper(teacherPose: self.teacherPose,studentPose: studentPose)
            var (teacherScaledPose,scoredStudentPose) = scaledPoseHelper.getScaledPose()
            
            
            //ここまでポーズ
            teacherScaledPose.confidence = self.teacherPose.confidence
            
            
            
            
            //print(poses)
            //            movieScaledPreviewImageView.show(poses: [teacherScaledPose], on: currentFrame, isFrameDraw: false)
            
            //座標データ？
            self.videoPreviewImageView.show(scaledPose: teacherScaledPose, studentPose: scoredStudentPose, on: currentFrame, isFrameDraw: true)
            
            self.videoCurrentFrame = nil
        }
        
    }
}

// MARK: - PoseNetDelegate

extension ViewController: PoseNetDelegate {
    func poseNet(_ poseNet: PoseNet, didPredict predictions: PoseNetOutput) {
        if (poseNet.type == "video"){
            
            defer {
                // Release `currentFrame` when exiting this method.
                self.videoCurrentFrame = nil
            }
            
            guard let currentFrame = videoCurrentFrame else {
                return
            }
            
            let poseBuilder = PoseBuilder(output: predictions,
                                          configuration: poseBuilderConfiguration,
                                          inputImage: currentFrame)
            
            
            let poses = algorithm == .single
            ? [poseBuilder.pose]
            : poseBuilder.poses
            //            print("student:",poses)
            
            if(poses.count==0){
                return
            }
            
            let studentPose = poses[0]
            
            let scaledPoseHelper = ScaledPoseHelper(teacherPose: self.teacherPose,studentPose: studentPose)
            var (teacherScaledPose,scoredStudentPose) = scaledPoseHelper.getScaledPose()
            
            
            //ここまでポーズ
            teacherScaledPose.confidence = self.teacherPose.confidence
            
            
            
            
            //print(poses)
            //            movieScaledPreviewImageView.show(poses: [teacherScaledPose], on: currentFrame, isFrameDraw: false)
            
            //座標データ？
            videoPreviewImageView.show(scaledPose: teacherScaledPose, studentPose: scoredStudentPose, on: currentFrame, isFrameDraw: true)
            
            //UILabel
            ScoreLabel.text = String(teacherScaledPose.score)
            
            
        }else{
            
            defer {
                // Release `currentFrame` when exiting this method.
                self.movieCurrentFrame = nil
            }
            
            guard let currentFrame = movieCurrentFrame else {
                return
            }
            
            let poseBuilder = PoseBuilder(output: predictions,
                                          configuration: poseBuilderConfiguration,
                                          inputImage: currentFrame)
            
            
            let poses = algorithm == .single
            ? [poseBuilder.pose]
            : poseBuilder.poses
            
            //            print("teacher:",poses)
            //ここに入れる
            // 先生のポーズ
            if let firstPose = poses.first {
                self.teacherPose = firstPose
                
                // moviePreviewImageView.show の呼び出しを修正
                moviePreviewImageView.show(scaledPose: firstPose, studentPose: firstPose, on: currentFrame, isFrameDraw: true)
            } else {
                print("No pose available for moviePreviewImageView")
            }
            
        }
    }
}
