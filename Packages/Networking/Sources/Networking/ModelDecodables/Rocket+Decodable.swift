import Foundation
import Model

extension Rocket: Decodable {

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
        case kilograms = "kg"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let description = try container.decode(String.self, forKey: .description)
        let firstFlight = try container.decode(Date.self, forKey: .firstFlight)
        let photos = try container.decode([String].self, forKey: .photos)
        let stageOne = try container.decode(Stage.self, forKey: .firstStage)
        let stageTwo = try container.decode(Stage.self, forKey: .secondStage)

        let heightContainer = try container.nestedContainer(keyedBy: LengthUnitCodingKeys.self, forKey: .height)
        let height = try heightContainer.decode(Double.self, forKey: .meters)
        let diameterContainer = try container.nestedContainer(keyedBy: LengthUnitCodingKeys.self, forKey: .diameter)
        let diameter = try diameterContainer.decode(Double.self, forKey: .meters)
        let massContainer = try container.nestedContainer(keyedBy: MassUnitCodingKeys.self, forKey: .mass)
        let mass = try massContainer.decode(Double.self, forKey: .kilograms)

        self.init(
            id: id,
            name: name,
            description: description,
            height: height,
            diameter: diameter,
            mass: mass,
            firstFlight: firstFlight,
            photos: photos,
            stageOne: stageOne,
            stageTwo: stageTwo
        )
    }

}
