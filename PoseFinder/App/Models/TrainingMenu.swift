import Foundation

struct TrainingMenu: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let focusPoints: [String]
    let estimatedDurationMinutes: Int?

    static let sampleData: [TrainingMenu] = [
        TrainingMenu(
            id: "squat",
            title: "スクワット",
            description: "下半身全体を鍛える基本メニュー。股関節と膝の連動を意識し、背筋を伸ばして行う。",
            focusPoints: [
                "膝がつま先より前に出ないようにする",
                "胸を張り背中を丸めない",
                "かかとに体重を乗せる"
            ],
            estimatedDurationMinutes: 5
        ),
        TrainingMenu(
            id: "deadlift",
            title: "デッドリフト",
            description: "背面全体を使う複合トレーニング。腰を痛めないフォームの習得が重要。",
            focusPoints: [
                "背中をまっすぐ保つ",
                "バーを体に近づけたまま引き上げる",
                "肩をすくめず、肩甲骨を寄せる"
            ],
            estimatedDurationMinutes: 4
        ),
        TrainingMenu(
            id: "pushup",
            title: "プッシュアップ",
            description: "上半身の押す動作を鍛える自重トレーニング。胸・肩・腕をバランスよく鍛える。",
            focusPoints: [
                "身体を一直線に保つ",
                "肘は45度程度に開く",
                "胸を床に近づけて十分に下ろす"
            ],
            estimatedDurationMinutes: 3
        )
    ]
}
