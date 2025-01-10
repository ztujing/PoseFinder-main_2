//
//  ScaledPoseHelper.swift
//  PoseFinder
//
//  Created by tujing on 2023/07/11.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation

class ScaledPoseHelper {
    var teacherPose = Pose()
    var scaledPose = Pose()
    var studentPose = Pose()
    var teacherCenterOfGravity:CGPoint? = CGPoint()
    var studentCenterOfGravity:CGPoint? = CGPoint()
    var ratio = TeacherStudentRatio.getInstance()
    
    init (teacherPose: Pose,studentPose: Pose) {
        self.teacherPose = teacherPose;
        self.studentPose = studentPose;
        //先生のグラビティを計算
        self.teacherCenterOfGravity = self.multiply(0.25, add(add(rawP("rSh"), rawP("lSh")),add(rawP("rHi"), rawP("lHi"))));
        print("teacherCenterOfGravity:",teacherCenterOfGravity)
        //生徒のグラビティを計算
        self.studentCenterOfGravity = self.multiply(0.25, add(add(rawSP("rSh"), rawSP("lSh")),add(rawSP("rHi"), rawSP("lHi"))));
        print("studentCenterOfGravity:",studentCenterOfGravity)
    }
    func rePos (position:CGPoint?) -> CGPoint {
        if let pos = self.add(position,self.studentCenterOfGravity) {
            return pos
        }
        return CGPoint(x: 0,y: 0)
    }
    
//    // 生徒の重心から先生の重心を引き算するメソッド
//       func computeCenterOfGravityDifference() -> CGPoint? {
//           guard let teacherCenter = teacherCenterOfGravity,
//                 let studentCenter = studentCenterOfGravity else {
//               return nil
//           }
//           
//           return CGPoint(x: studentCenter.x - teacherCenter.x, y: studentCenter.y - teacherCenter.y)
//     }
    
    func getScaledPose () -> (Pose, Pose) {
//        guard let centerOfGravityDifference = computeCenterOfGravityDifference() else {
//                // 重心を計算できなかった場合は空のポーズを返します
//                return Pose()
//            }
//            
//            // 各関節の位置をスケーリングする前に、生徒のポーズ全体を生徒の重心を中心に移動させます
//        for joint in studentPose.joints {
//            // 生徒のポーズ全体を生徒の重心の差分だけ移動させます
//            joint.value.position = CGPoint(x: joint.value.position.x - centerOfGravityDifference.x, y: joint.value.position.y - centerOfGravityDifference.y)
//        }
        
        guard let tRSh = p("rSh"),let sRSh = sp("rSh") else {
            return (Pose(), Pose())
        }
        // 比率
        var sLength = sqrt(sRSh.x*sRSh.x+sRSh.y*sRSh.y)
        var tLength = sqrt(tRSh.x*tRSh.x+tRSh.y*tRSh.y)
        if (tLength == 0 ){
            return (Pose(), Pose())
        }
        var tsRatio = sLength/tLength
        print("tsRatio:",tsRatio)
        
        // 総合スコア
        var totalScore = 0.0
        

        var scoreTh = 80.0  // 全ての関節の閾値を設定

        var scoreTh_rSh = scoreTh  // 右肩
        var scoreTh_rEl = scoreTh  // 右肘
        var scoreTh_rWr = scoreTh  // 右手首
        var scoreTh_rHi = scoreTh  // 右股関節
        var scoreTh_rKn = scoreTh  // 右膝
        var scoreTh_rAn = scoreTh  // 右足首
        var scoreTh_lSh = scoreTh  // 左肩
        var scoreTh_lEl = scoreTh  // 左肘
        var scoreTh_lWr = scoreTh  // 左手首
        var scoreTh_lHi = scoreTh  // 左股関節
        var scoreTh_lKn = scoreTh  // 左膝
        var scoreTh_lAn = scoreTh  // 左足首
        var scoreTh_rEa = scoreTh  // 右耳
        var scoreTh_lEa = scoreTh  // 左耳
        
        
        //rightShoulder
        
        
        var pos_rSh = self.multiply(ratio.originToRightShoulder, p("rSh"))
        // scaledPoseがStudentPoseになるように比率を掛け算する
        pos_rSh = self.multiply(tsRatio,pos_rSh)
        self.scaledPose.joints[.rightShoulder]?.position = rePos(position: pos_rSh)
        if (pos_rSh != nil) {
            self.scaledPose.joints[.rightShoulder]?.confidence = 1.0
            self.scaledPose.joints[.rightShoulder]?.isValid = true
            
            if let tP = self.scaledPose.joints[.rightShoulder]?.position,
               let sP = self.studentPose.joints[.rightShoulder]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
//                print("rSh_(tP,sP,distance):",tP,sP,distance)
                self.studentPose.joints[.rightShoulder]?.score = max((scoreTh_rSh-distance)/scoreTh_rSh,0)
            }
        } else {
            self.scaledPose.joints[.rightShoulder]?.confidence = 0.0
            self.scaledPose.joints[.rightShoulder]?.isValid = false
            self.studentPose.joints[.rightShoulder]?.score = 0.0
        }
        totalScore += self.studentPose.joints[.rightShoulder]?.score ?? 0.0
        
        
        //rightElbow
        
        var pos_rEl = self.multiply(tsRatio,self.multiply(ratio.rightShoulderToRightElbow, self.sub(p("rEl"),p("rSh"))))
        pos_rEl = self.add(pos_rSh,pos_rEl)
        self.scaledPose.joints[.rightElbow]?.position = rePos(position: pos_rEl)
        if(pos_rEl != nil) {
            self.scaledPose.joints[.rightElbow]?.confidence = 1.0
            self.scaledPose.joints[.rightElbow]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.rightElbow]?.position,
               let sP = self.studentPose.joints[.rightElbow]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
                //                print("distance:",distance)
                self.studentPose.joints[.rightElbow]?.score = max((scoreTh_rEl-distance)/scoreTh_rEl,0)
            }
        }else {
            self.scaledPose.joints[.rightElbow]?.confidence = 0.0
            self.scaledPose.joints[.rightElbow]?.isValid =  false
            self.studentPose.joints[.rightElbow]?.score = 0.0
            
        }
        
        totalScore += self.studentPose.joints[.rightElbow]?.score ?? 0.0
        
        
        //rightWrist
        
        var pos_rWr = self.multiply(tsRatio,multiply(ratio.rightElbowToRightWrist, self.sub(p("rWr"),p("rEl"))))
        pos_rWr = self.add(pos_rEl,pos_rWr)
        self.scaledPose.joints[.rightWrist]?.position = rePos(position: pos_rWr)
        if(pos_rWr != nil) {
            self.scaledPose.joints[.rightWrist]?.confidence = 1.0
            self.scaledPose.joints[.rightWrist]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.rightWrist]?.position,
               let sP = self.studentPose.joints[.rightWrist]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
                //                print("distance:",distance)
                self.studentPose.joints[.rightWrist]?.score = max((scoreTh_rWr-distance)/scoreTh_rWr,0)
            }
            
        }else {
            self.scaledPose.joints[.rightWrist]?.confidence = 0.0
            self.scaledPose.joints[.rightWrist]?.isValid =  false
            self.studentPose.joints[.rightWrist]?.score = 0.0
            
        }
        totalScore += self.studentPose.joints[.rightWrist]?.score ?? 0.0
        
        //rightHip
        
        var pos_rHi = self.multiply(ratio.originToRightHip, p("rHi"))
        pos_rHi = self.multiply(tsRatio,pos_rHi)
        self.scaledPose.joints[.rightHip]?.position = rePos(position: pos_rHi)
        if(pos_rHi != nil) {
            self.scaledPose.joints[.rightHip]?.confidence = 1.0
            self.scaledPose.joints[.rightHip]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.rightHip]?.position,
               let sP = self.studentPose.joints[.rightHip]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
//                print("rHi_(tP,sP,distance):",tP,sP,distance)
                self.studentPose.joints[.rightHip]?.score = max((scoreTh_rHi-distance)/scoreTh_rHi,0)
            }
            
        }else {
            self.scaledPose.joints[.rightHip]?.confidence = 0.0
            self.scaledPose.joints[.rightHip]?.isValid =  false
            self.studentPose.joints[.rightHip]?.score = 0.0
            
        }
        totalScore += self.studentPose.joints[.rightHip]?.score ?? 0.0
        
        //rightKnee
        
        var pos_rKn = self.multiply(tsRatio,multiply(ratio.rightHipToRightKnee, self.sub(p("rKn"),p("rHi"))))
        pos_rKn = self.add(pos_rHi,pos_rKn)
        self.scaledPose.joints[.rightKnee]?.position = rePos(position: pos_rKn)
        if(pos_rKn != nil){
            self.scaledPose.joints[.rightKnee]?.confidence = 1.0
            self.scaledPose.joints[.rightKnee]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.rightKnee]?.position,
               let sP = self.studentPose.joints[.rightKnee]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
                //                print("distance:",distance)
                self.studentPose.joints[.rightKnee]?.score = max((scoreTh_rKn-distance)/scoreTh_rKn,0)
            }
        }else {
            self.scaledPose.joints[.rightKnee]?.confidence = 0.0
            self.scaledPose.joints[.rightKnee]?.isValid =  false
            self.studentPose.joints[.rightKnee]?.score = 0.0
            
        }
        totalScore += self.studentPose.joints[.rightKnee]?.score ?? 0.0
        
        //rightAnkle
        
        var pos_rAn = self.multiply(tsRatio,multiply(ratio.rightKneeToRightAnkle, self.sub(p("rAn"),p("rKn"))))
        pos_rAn = self.add(pos_rKn,pos_rAn)
        self.scaledPose.joints[.rightAnkle]?.position = rePos(position: pos_rAn)
        if(pos_rAn != nil) {
            self.scaledPose.joints[.rightAnkle]?.confidence = 0.0
            self.scaledPose.joints[.rightAnkle]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.rightAnkle]?.position,
               let sP = self.studentPose.joints[.rightAnkle]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
                //                print("distance:",distance)
                self.studentPose.joints[.rightAnkle]?.score = max((scoreTh_rAn-distance)/scoreTh_rAn,0)
            }
        }else {
            self.scaledPose.joints[.rightAnkle]?.confidence = 1.0
            self.scaledPose.joints[.rightAnkle]?.isValid =  false
            self.studentPose.joints[.rightAnkle]?.score = 0.0
            
        }
        totalScore += self.studentPose.joints[.rightAnkle]?.score ?? 0.0
        
        
        //left
        
        //leftShoulder
        
        var pos_lSh = self.multiply(ratio.originToLeftShoulder, p("lSh"))
        pos_lSh = self.multiply(tsRatio,pos_lSh)
        self.scaledPose.joints[.leftShoulder]?.position = rePos(position: pos_lSh)
//        print("***************lSh*****",p("lSh"),pos_lSh,rePos(position: pos_lSh),rawSP("lSh"))
        if(pos_lSh != nil) {
            self.scaledPose.joints[.leftShoulder]?.confidence = 1.0
            self.scaledPose.joints[.leftShoulder]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.leftShoulder]?.position,
               let sP = self.studentPose.joints[.leftShoulder]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
                print("lSh_(tP,sP,distance):",sP,tP,distance)
                self.studentPose.joints[.leftShoulder]?.score = max((scoreTh_lSh-distance)/scoreTh_lSh,0)
            }
        }else {
            self.scaledPose.joints[.leftShoulder]?.confidence = 0.0
            self.scaledPose.joints[.leftShoulder]?.isValid =  false
            self.studentPose.joints[.leftShoulder]?.score = 0.0
            
        }
        totalScore += self.studentPose.joints[.leftShoulder]?.score ?? 0.0
        
        //leftElbow
        
        var pos_lEl = self.multiply(tsRatio,multiply(ratio.leftShoulderToLeftElbow, self.sub(p("lEl"),p("lSh"))))
        pos_lEl = self.add(pos_lSh,pos_lEl)
        self.scaledPose.joints[.leftElbow]?.position = rePos(position: pos_lEl)
        if(pos_lEl != nil) {
            self.scaledPose.joints[.leftElbow]?.confidence = 1.0
            self.scaledPose.joints[.leftElbow]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.leftElbow]?.position,
               let sP = self.studentPose.joints[.leftElbow]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
                //                print("distance:",distance)
                self.studentPose.joints[.leftElbow]?.score = max((scoreTh_lEl-distance)/scoreTh_lEl,0)
            }
        }else {
            self.scaledPose.joints[.leftElbow]?.confidence = 0.0
            self.scaledPose.joints[.leftElbow]?.isValid =  false
            self.studentPose.joints[.leftElbow]?.score = 0.0
            
        }
        totalScore += self.studentPose.joints[.leftElbow]?.score ?? 0.0
        
        //leftWrist
        
        var pos_lWr = self.multiply(tsRatio,multiply(ratio.leftElbowToLeftWrist, self.sub(p("lWr"),p("lEl"))))
        pos_lWr = self.add(pos_lEl,pos_lWr)
        self.scaledPose.joints[.leftWrist]?.position = rePos(position: pos_lWr)
        if(pos_lWr != nil) {
            self.scaledPose.joints[.leftWrist]?.confidence = 1.0
            self.scaledPose.joints[.leftWrist]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.leftWrist]?.position,
               let sP = self.studentPose.joints[.leftWrist]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
                //                ・・("distance:",distance)
                self.studentPose.joints[.leftWrist]?.score = max((scoreTh_lWr-distance)/scoreTh_lWr,0)
            }
        }else {
            self.scaledPose.joints[.leftWrist]?.confidence = 0.0
            self.scaledPose.joints[.leftWrist]?.isValid =  false
            self.studentPose.joints[.leftWrist]?.score = 0.0
            
        }
        totalScore += self.studentPose.joints[.leftWrist]?.score ?? 0.0
        
        //leftHip
        
        var pos_lHi = self.multiply(ratio.originToLeftHip, p("lHi"))
        pos_lHi = self.multiply(tsRatio,pos_lHi)
        self.scaledPose.joints[.leftHip]?.position = rePos(position: pos_lHi)
        if(pos_lHi != nil) {
            self.scaledPose.joints[.leftHip]?.confidence = 1.0
            self.scaledPose.joints[.leftHip]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.leftHip]?.position,
               let sP = self.studentPose.joints[.leftHip]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
//                print("lHi_(sP,tP,distance):",sP,tP,distance)
                self.studentPose.joints[.leftHip]?.score = max((scoreTh_lHi-distance)/scoreTh_lHi,0)
            }
        }else {
            self.scaledPose.joints[.leftHip]?.confidence = 0.0
            self.scaledPose.joints[.leftHip]?.isValid =  false
            self.studentPose.joints[.leftHip]?.score = 0.0
            
        }
        totalScore += self.studentPose.joints[.leftHip]?.score ?? 0.0
        
        //leftKnee
        
        var pos_lKn = self.multiply(tsRatio,multiply(ratio.leftHipToLeftKnee, self.sub(p("lKn"),p("lHi"))))
        pos_lKn = self.add(pos_lHi,pos_lKn)
        self.scaledPose.joints[.leftKnee]?.position = rePos(position: pos_lKn)
        if(pos_lKn != nil){
            self.scaledPose.joints[.leftKnee]?.confidence = 1.0
            self.scaledPose.joints[.leftKnee]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.leftKnee]?.position,
               let sP = self.studentPose.joints[.leftKnee]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
                //                print("distance:",distance)
                self.studentPose.joints[.leftKnee]?.score = max((scoreTh_lKn-distance)/scoreTh_lKn,0)
            }
        }else {
            self.scaledPose.joints[.leftKnee]?.confidence = 0.0
            self.scaledPose.joints[.leftKnee]?.isValid =  false
            self.studentPose.joints[.leftKnee]?.score = 0.0
            
        }
        totalScore += self.studentPose.joints[.leftKnee]?.score ?? 0.0
        
        
        //leftAnkle
        
        var pos_lAn = self.multiply(tsRatio,multiply(ratio.leftKneeToLeftAnkle, self.sub(p("lAn"),p("lKn"))))
        pos_lAn = self.add(pos_lKn,pos_lAn)
        self.scaledPose.joints[.leftAnkle]?.position = rePos(position: pos_lAn)
        if(pos_lAn != nil) {
            self.scaledPose.joints[.leftAnkle]?.confidence = 1.0
            self.scaledPose.joints[.leftAnkle]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.leftAnkle]?.position,
               let sP = self.studentPose.joints[.leftAnkle]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
                //                print("distance:",distance)
                self.studentPose.joints[.leftAnkle]?.score = max((scoreTh_lAn-distance)/scoreTh_lAn,0)
            }
        }else {
            self.scaledPose.joints[.leftAnkle]?.confidence = 0.0
            self.scaledPose.joints[.leftAnkle]?.isValid =  false
            self.studentPose.joints[.leftAnkle]?.score = 0.0
            
        }
        totalScore += self.studentPose.joints[.leftAnkle]?.score ?? 0.0
        
        
        //face
        
        //(midpoint)
        var midpoint = multiply(0.5,self.add(p("rSh"),p("lSh")))
        var pos_midpoint = multiply(0.5,self.add(pos_rSh,pos_lSh))
        
        
        //rightEar
        
        var pos_rEa = self.multiply(tsRatio,multiply(ratio.midpointOfShouldersToRightEar, self.sub(p("rEa"),midpoint)))
        pos_rEa = self.add(pos_midpoint,pos_rEa)
        self.scaledPose.joints[.rightEar]?.position = rePos(position: pos_rEa)
        if(pos_rEa != nil) {
            self.scaledPose.joints[.rightEar]?.confidence = 1.0
            self.scaledPose.joints[.rightEar]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.rightEar]?.position,
               let sP = self.studentPose.joints[.rightEar]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
                //                print("distance:",distance)
                self.studentPose.joints[.rightEar]?.score = max((scoreTh_rEa-distance)/scoreTh_rEa,0)
            }
        }else {
            self.scaledPose.joints[.rightEar]?.confidence = 0.0
            self.scaledPose.joints[.rightEar]?.isValid =  false
            self.studentPose.joints[.rightEar]?.score = 0.0
            
        }
        totalScore += self.studentPose.joints[.rightEar]?.score ?? 0.0
        
        
        //leftEar
        
        var pos_lEa = self.multiply(tsRatio,multiply(ratio.midpointOfShouldersToLeftEar, self.sub(p("lEa"),midpoint)))
        pos_lEa = self.add(pos_midpoint,pos_lEa)
        self.scaledPose.joints[.leftEar]?.position = rePos(position: pos_lEa)
        if(pos_lEa != nil) {
            self.scaledPose.joints[.leftEar]?.confidence = 1.0
            self.scaledPose.joints[.leftEar]?.isValid =  true
            
            if let tP = self.scaledPose.joints[.leftEar]?.position,
               let sP = self.studentPose.joints[.leftEar]?.position {
                
                var distance = sqrt(pow(tP.x-sP.x,2)+pow(tP.y-sP.y,2))
                //                print("distance:",distance)
                self.studentPose.joints[.leftEar]?.score = max((scoreTh_lEa-distance)/scoreTh_lEa,0)
            }
        }else {
            self.scaledPose.joints[.leftEar]?.confidence = 0.0
            self.scaledPose.joints[.leftEar]?.isValid =  false
            self.studentPose.joints[.leftEar]?.score = 0.0
            
        }
        totalScore += self.studentPose.joints[.leftEar]?.score ?? 0.0
        
        
        scaledPose.confidence = teacherPose.confidence
        
        totalScore /= 14
        print("totalScore",totalScore)
    
        studentPose.score = totalScore
        // 重心を計算して引き算
        
        return (scaledPose,studentPose)
    }
    
    //add
    func add(_ positionA: CGPoint?, _ positionB: CGPoint?) -> CGPoint?
    {
        guard let posA = positionA,let posB = positionB else {
            return nil;
        }
        return CGPoint(x: posA.x + posB.x, y: posA.y + posB.y);
    }
    //sub
    func sub(_ positionA: CGPoint?, _ positionB: CGPoint?) -> CGPoint?
    {
        guard let posA = positionA,let posB = positionB else {
            return nil;
        }
        return CGPoint(x: posA.x - posB.x, y: posA.y - posB.y);
    }
    //multiply
    func multiply(_ a:Double?, _ position: CGPoint?) -> CGPoint?
    {
        guard let a1 = a,let pos = position else {
            return nil;
        }
        return CGPoint(x: a1*pos.x, y: a1*pos.y);
    }
    
    //p
    func p(_ name:String) -> CGPoint?
    {
        return self.sub(self.rawP(name), self.teacherCenterOfGravity);
    }
    //sp
    func sp(_ name:String) -> CGPoint?
    {
        return self.sub(self.rawSP(name), self.studentCenterOfGravity);
    }
    //rawP
    func rawSP(_ name: String) -> CGPoint?
    {
        return rawPosition(name,self.studentPose)
    }
    func rawP(_ name: String) -> CGPoint?
    {
        return rawPosition(name,self.teacherPose)
    }
    func rawPosition(_ name: String,_ pose: Pose) -> CGPoint?
    {
        
        if(name == "nos"){
            return pose.joints[.nose]?.position;
        }else if (name == "lEy"){
            return pose.joints[.leftEye]?.position;
        }else if (name == "lEa"){
            return pose.joints[.leftEar]?.position;
        }else if (name == "lSh"){
            return pose.joints[.leftShoulder]?.position;
        }else if (name == "lEl"){
            return pose.joints[.leftElbow]?.position;
        }else if (name == "lWr"){
            return pose.joints[.leftWrist]?.position;
        }else if (name == "lHi"){
            return pose.joints[.leftHip]?.position;
        }else if (name == "lKn"){
            return pose.joints[.leftKnee]?.position;
        }else if (name == "lAn"){
            return pose.joints[.leftAnkle]?.position;
        }else if (name == "rEy"){
            return pose.joints[.rightEye]?.position;
        }else if (name == "rEa"){
            return pose.joints[.rightEar]?.position;
        }else if (name == "rSh"){
            return pose.joints[.rightShoulder]?.position;
        }else if (name == "rEl"){
            return pose.joints[.rightElbow]?.position;
        }else if (name == "rWr"){
            return pose.joints[.rightWrist]?.position;
        }else if (name == "rHi"){
            return pose.joints[.rightHip]?.position;
        }else if (name == "rKn"){
            return pose.joints[.rightKnee]?.position;
        }else if (name == "rAn"){
            return pose.joints[.rightAnkle]?.position;
        }
        return nil
    }
    
    
}
