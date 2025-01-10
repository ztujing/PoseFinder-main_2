/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Implementation details of a view that visualizes the detected poses.
 */

import UIKit

@IBDesignable
class PoseImageView: UIImageView {
    
    // 教師と生徒の色を定義
    let teacherColor = UIColor.blue
    let studentColor = UIColor.red
    
    /// A data structure used to describe a visual connection between two joints.
    struct JointSegment {
        let jointA: Joint.Name
        let jointB: Joint.Name
    }
    
    /// An array of joint-pairs that define the lines of a pose's wireframe drawing.
    static let jointSegments = [
        // The connected joints that are on the left side of the body.
        JointSegment(jointA: .leftHip, jointB: .leftShoulder),
        JointSegment(jointA: .leftShoulder, jointB: .leftElbow),
        JointSegment(jointA: .leftElbow, jointB: .leftWrist),
        JointSegment(jointA: .leftHip, jointB: .leftKnee),
        JointSegment(jointA: .leftKnee, jointB: .leftAnkle),
        // The connected joints that are on the right side of the body.
        JointSegment(jointA: .rightHip, jointB: .rightShoulder),
        JointSegment(jointA: .rightShoulder, jointB: .rightElbow),
        JointSegment(jointA: .rightElbow, jointB: .rightWrist),
        JointSegment(jointA: .rightHip, jointB: .rightKnee),
        JointSegment(jointA: .rightKnee, jointB: .rightAnkle),
        // The connected joints that cross over the body.
        JointSegment(jointA: .leftShoulder, jointB: .rightShoulder),
        JointSegment(jointA: .leftHip, jointB: .rightHip)
    ]
    
    /// The width of the line connecting two joints.
    @IBInspectable var segmentLineWidth: CGFloat = 2
    /// The color of the line connecting two joints.
    @IBInspectable var segmentColor: UIColor = UIColor.systemTeal
    /// The radius of the circles drawn for each joint.
    @IBInspectable var jointRadius: CGFloat = 4
    /// The color of the circles drawn for each joint.
    @IBInspectable var jointColor: UIColor = UIColor.systemPink
    
    // MARK: - Rendering methods
    
    /// Returns an image showing the detected poses.
    ///
    /// - parameters:
    ///     - poses: An array of detected poses.
    ///     - frame: The image used to detect the poses and used as the background for the returned image.
    func show(scaledPose: Pose, studentPose: Pose, on frame: CGImage ,isFrameDraw: Bool) {
        
        //Visualize the Detected Poses [検出されたポーズを視覚化する]
        //For each detected pose, the sample app draws a wireframe over the input image, connecting the lines between the joints and then drawing circles for the joints themselves. [サンプルアプリは、検出されたポーズごとに、入力画像上にワイヤーフレームを描画し、関節間の線を接続してから、関節自体の円を描画します。]
        
        
        
        let dstImageSize = CGSize(width: frame.width, height: frame.height)
        let dstImageFormat = UIGraphicsImageRendererFormat()
        
        dstImageFormat.scale = 1
        let renderer = UIGraphicsImageRenderer(size: dstImageSize,
                                               format: dstImageFormat)
        
        let dstImage = renderer.image { rendererContext in
            // Draw the current frame as the background for the new image.
            if isFrameDraw {
                draw(image: frame, in: rendererContext.cgContext)
            }
            
            // 教師の姿勢を描画
            drawPose(pose: scaledPose, in: rendererContext.cgContext, color: teacherColor)
            
            // 生徒の姿勢を描画
            drawPose(pose: studentPose, in: rendererContext.cgContext, color: studentColor)
            
        }
        
        image = dstImage
        //print(image)
        
    }
    
    
    // 新しいメソッド
    private func drawPose(pose: Pose, in context: CGContext, color: UIColor) {
        for segment in PoseImageView.jointSegments {
            let jointA = pose[segment.jointA]
            let jointB = pose[segment.jointB]
            
            guard jointA.isValid, jointB.isValid else {
                continue
            }
            
            drawLine(from: jointA, to: jointB, in: context, color: color)
        }
        
        for joint in pose.joints.values.filter({ $0.isValid }) {
            let jointColor = colorBasedOnScore(joint.score)
            draw(circle: joint, color: jointColor, in: context)
        }
    }
    
    /// Vertically flips and draws the given image.
    ///
    /// - parameters:
    ///     - image: The image to draw onto the context (vertically flipped).
    ///     - cgContext: The rendering context.
    func draw(image: CGImage, in cgContext: CGContext) {
        cgContext.saveGState()
        // The given image is assumed to be upside down; therefore, the context
        // is flipped before rendering the image.
        cgContext.scaleBy(x: 1.0, y: -1.0)
        // Render the image, adjusting for the scale transformation performed above.
        let drawingRect = CGRect(x: 0, y: -image.height, width: image.width, height: image.height)
        //print(drawingRect)
        cgContext.draw(image, in: drawingRect)
        cgContext.restoreGState()
    }
    
    /// Draws a line between two joints.
    ///
    /// - parameters:
    ///     - parentJoint: A valid joint whose position is used as the start position of the line.
    ///     - childJoint: A valid joint whose position is used as the end of the line.
    ///     - cgContext: The rendering context.
    func drawLine(from parentJoint: Joint,
                  to childJoint: Joint,
                  in cgContext: CGContext,
                  color: UIColor) {
        cgContext.setStrokeColor(color.cgColor)
        cgContext.setLineWidth(segmentLineWidth)
        //print(parentJoint.position)
        cgContext.move(to: parentJoint.position)
        cgContext.addLine(to: childJoint.position)
        cgContext.strokePath()
    }
    
    /// Draw a circle in the location of the given joint.
    ///
    /// - parameters:
    ///     - circle: A valid joint whose position is used as the circle's center.
    ///     - cgContext: The rendering context.
    private func draw(circle joint: Joint, color: UIColor, in cgContext: CGContext) {
        
        cgContext.setFillColor(color.cgColor)
        
        let rectangle = CGRect(x: joint.position.x - jointRadius, y: joint.position.y - jointRadius,
                               width: jointRadius * 2, height: jointRadius * 2)
        cgContext.addEllipse(in: rectangle)
        cgContext.drawPath(using: .fill)
    }
    
    // スコアに基づいて色を決定する補助関数
    private func colorBasedOnScore(_ score: Double) -> UIColor {
        // スコアが0から1の範囲であると仮定
        // スコアが低いほど赤に近く、高いほど緑に近くなる
        return UIColor(red: CGFloat(1 - score), green: CGFloat(score), blue: 0, alpha: 1)
    }
}
