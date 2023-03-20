import Foundation

struct Rocket: Identifiable, Equatable, Decodable {

    struct Stage: Equatable, Codable {
        var reusable: Bool
        var engines: Int
        var fuelAmountTons: Double
        var burnTimeSec: Double?
    }

    var id: String
    var name: String
    var description: String
    var height: Double
    var diameter: Double
    var mass: Double
    var firstFlight: Date
    var photos: [String]
    var stages: [Stage]

    enum CodingKeys: String, CodingKey {
        case id = "rocketId"
        case name = "rocketName"
        case description
        case height
        case diameter
        case mass
        case firstFlight
        case photos = "flickrImages"
        case firstStage
        case secondStage
    }

    enum LengthUnitCodingKeys: String, CodingKey {
        case meters
    }

    enum MassUnitCodingKeys: String, CodingKey {
        case kg
    }

    init(id: String, name: String, description: String, height: Double, diameter: Double, mass: Double, firstFlight: Date, photos: [String], stages: [Stage]) {
        self.id = id
        self.name = name
        self.description = description
        self.height = height
        self.diameter = diameter
        self.mass = mass
        self.firstFlight = firstFlight
        self.photos = photos
        self.stages = stages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        firstFlight = try container.decode(Date.self, forKey: .firstFlight)
        photos = try container.decode([String].self, forKey: .photos)

        let heightContainer = try container.nestedContainer(keyedBy: LengthUnitCodingKeys.self, forKey: .height)
        height = try heightContainer.decode(Double.self, forKey: .meters)
        let diameterContainer = try container.nestedContainer(keyedBy: LengthUnitCodingKeys.self, forKey: .diameter)
        diameter = try diameterContainer.decode(Double.self, forKey: .meters)
        let massContainer = try container.nestedContainer(keyedBy: MassUnitCodingKeys.self, forKey: .mass)
        mass = try massContainer.decode(Double.self, forKey: .kg)

        stages = []
        if let stage = try? container.decode(Stage.self, forKey: .firstStage) {
            stages.append(stage)
        }
        if let stage = try? container.decode(Stage.self, forKey: .secondStage) {
            stages.append(stage)
        }
    }

    static var mocks: [Rocket] {
        [
            Rocket(
                id: "falcon1",
                name: "Falcon 1",
                description: "The Falcon 1 was an expendable launch system privately developed and manufactured by SpaceX during 2006-2009. On 28 September 2008, Falcon 1 became the first privately-developed liquid-fuel launch vehicle to go into orbit around the Earth.",
                height: 22.25,
                diameter: 1.68,
                mass: 30146,
                firstFlight: Date().addingTimeInterval(-365 * 24 * 60 * 60),
                photos: [
                    "https://imgur.com/DaCfMsj.jpg",
                    "https://imgur.com/azYafd8.jpg"
                ],
                stages: [
                    Stage(reusable: false, engines: 1, fuelAmountTons: 44.3, burnTimeSec: 169),
                    Stage(reusable: false, engines: 1, fuelAmountTons: 3.38, burnTimeSec: 378)
                ]
            ),
            Rocket(
                id: "falcon9",
                name: "Falcon 9",
                description: "Falcon 9 is a two-stage rocket designed and manufactured by SpaceX for the reliable and safe transport of satellites and the Dragon spacecraft into orbit.",
                height: 70,
                diameter: 3.7,
                mass: 549054,
                firstFlight: Date().addingTimeInterval(-5 * 365 * 24 * 60 * 60),
                photos: [
                    "https://farm1.staticflickr.com/929/28787338307_3453a11a77_b.jpg",
                    "https://farm4.staticflickr.com/3955/32915197674_eee74d81bb_b.jpg",
                    "https://farm1.staticflickr.com/293/32312415025_6841e30bf1_b.jpg"
                ],
                stages: [
                    Stage(reusable: true, engines: 9, fuelAmountTons: 385, burnTimeSec: 162),
                    Stage(reusable: false, engines: 1, fuelAmountTons: 90, burnTimeSec: 397)
                ]
            )
        ]
    }
}
