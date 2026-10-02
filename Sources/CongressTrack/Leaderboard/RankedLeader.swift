struct RankedLeader: Identifiable {
    var id: String { leader.id }
    let rank: Int
    let leader: LeaderboardEntry
}
