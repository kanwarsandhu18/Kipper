import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @State private var isResponding = false // Track if the assistant is providing an answer
    
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let scene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(scene)
                
                // Create a virtual assistant entity, like an orb
                let assistantEntity = createVirtualAssistant()
                content.add(assistantEntity)
                
                // Animate the assistant to glow when responding
                if isResponding {
                    addGlowEffect(to: assistantEntity as! ModelEntity)
                }
            }
        }
    }

    func createVirtualAssistant() -> Entity {
        let assistantEntity = ModelEntity(mesh: .generateSphere(radius: 0.3)) // For example, a sphere as an assistant
        assistantEntity.transform = Transform(scale: [0.5, 0.5, 0.5], rotation: .init(), translation: [0, 1, 0])
        
        // Set an initial material without glow
        var material = SimpleMaterial()
        material.color = .init(tint: .blue, texture: nil) // Initial blue color
        assistantEntity.model?.materials = [material]

        return assistantEntity
    }

    func addGlowEffect(to entity: ModelEntity) {
        // Create an emissive material to simulate glow
        var glowingMaterial = SimpleMaterial()
        glowingMaterial.color = .init(tint: .green, texture: nil)
        
        // Animate the glow (pulsating effect)
        let glowAnimation = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let scaleUp = Transform(scale: [0.55, 0.55, 0.55], rotation: .init(), translation: [0, 1, 0])
            let scaleDown = Transform(scale: [0.5, 0.5, 0.5], rotation: .init(), translation: [0, 1, 0])
            
            // Alternate scaling to simulate pulsating glow
            entity.move(to: scaleUp, relativeTo: entity, duration: 0.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                entity.move(to: scaleDown, relativeTo: entity, duration: 0.5)
            }
        }
        glowAnimation.fire() // Start the animation
        
        entity.model?.materials = [glowingMaterial] // Apply the glowing material
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}

