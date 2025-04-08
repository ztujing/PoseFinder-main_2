import CoreGraphics
import MLKitPoseDetection // ML Kit の Pose Detection API を利用する場合のインポート例（環境に応じて調整してください）

/// ML Kit の Pose Landmark と内部の Joint.Name の対応を定義する拡張
extension Joint.Name {
    /// ML Kit の Pose Landmark Type との対応を返す
    var mlKitLandmarkType: PoseLandmarkType {
        switch self {
        case .nose:
            return .nose
        case .leftEye:
            return .leftEyeInner // ML Kit では leftEyeOuter/leftEyeInner 等が存在する場合もあるので、適宜選択
        case .rightEye:
            return .rightEyeInner
        case .leftEar:
            return .leftEar
        case .rightEar:
            return .rightEar
        case .leftShoulder:
            return .leftShoulder
        case .rightShoulder:
            return .rightShoulder
        case .leftElbow:
            return .leftElbow
        case .rightElbow:
            return .rightElbow
        case .leftWrist:
            return .leftWrist
        case .rightWrist:
            return .rightWrist
        case .leftHip:
            return .leftHip
        case .rightHip:
            return .rightHip
        case .leftKnee:
            return .leftKnee
        case .rightKnee:
            return .rightKnee
        case .leftAnkle:
            return .leftAnkle
        case .rightAnkle:
            return .rightAnkle
        }
    }
}

/// PoseBuilderConfiguration は、各種パラメータを保持する構造体（例として関節信頼度閾値のみ定義）
//struct PoseBuilderConfiguration {
//    /// 関節の有効性を判断するための信頼度閾値
//    let jointConfidenceThreshold: Double
//}

/// PoseBuilderV2
/// ML Kit の検出結果（シングルパーソン）から内部の Pose オブジェクトを構築する
struct PoseBuilderV2 {
    /// ML Kit の検出結果。ここでは MLKitPose 型（ML Kit API の Pose 型）とする
    let mlKitPose: MLKitPoseDetectionCommon.Pose
    let configuration: PoseBuilderConfiguration
    
    /// 初期化
    init(mlKitPose: MLKitPoseDetectionCommon.Pose, configuration: PoseBuilderConfiguration) {
        self.mlKitPose = mlKitPose
        self.configuration = configuration
    }
    
    /// ML Kit の検出結果から内部 Pose オブジェクトを構築する
    var pose: Pose {
        var pose = Pose()
        
        // 内部で保持している各関節について、ML Kit の検出結果から情報を取得して更新する
        for jointName in Joint.Name.allCases {
            // ML Kit の検出結果から、対応する Landmark を取得する
            // landmark(ofType:) は ML Kit の Pose オブジェクトが提供するメソッドとして想定
            let landmark = mlKitPose.landmark(ofType: jointName.mlKitLandmarkType)
            var joint = pose[jointName]
            // ML Kit で得られるランドマークの位置は CGPoint 型（または類似の型）と想定
            joint.position = CGPoint(x: landmark.position.x, y: landmark.position.y)
            // ML Kit の inFrameLikelihood を信頼度として利用（0〜1 の範囲）
            joint.confidence = Double(landmark.inFrameLikelihood)
            joint.isValid = joint.confidence >= configuration.jointConfidenceThreshold
            pose[jointName] = joint
            
        }
        
        // 全関節の信頼度の平均をポーズ全体の信頼度とする
        pose.confidence = pose.joints.values
            .map { $0.confidence }
            .reduce(0, +) / Double(Joint.numberOfJoints)
        
        return pose
    }
}
