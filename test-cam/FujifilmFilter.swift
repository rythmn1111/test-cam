//
//  FujifilmFilter.swift
//  test-cam
//
//  Film simulation filters inspired by Fujifilm cameras
//

import CoreImage
import UIKit

class FujifilmFilter {
    private let context = CIContext()

    enum FilmSimulation {
        case classicChrome
        case velvia
        case provia
        case astia

        var name: String {
            switch self {
            case .classicChrome: return "Classic Chrome"
            case .velvia: return "Velvia"
            case .provia: return "Provia"
            case .astia: return "Astia"
            }
        }
    }

    func applyFilter(to image: UIImage, simulation: FilmSimulation = .classicChrome) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        var filteredImage = ciImage

        switch simulation {
        case .classicChrome:
            filteredImage = applyClassicChrome(to: filteredImage)
        case .velvia:
            filteredImage = applyVelvia(to: filteredImage)
        case .provia:
            filteredImage = applyProvia(to: filteredImage)
        case .astia:
            filteredImage = applyAstia(to: filteredImage)
        }

        // Add subtle film grain for authenticity
        filteredImage = addFilmGrain(to: filteredImage)

        guard let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage)
    }

    // Classic Chrome: Muted colors, enhanced shadows, perfect for restaurants
    private func applyClassicChrome(to image: CIImage) -> CIImage {
        var result = image

        // Reduce saturation slightly for that muted film look
        if let saturationFilter = CIFilter(name: "CIColorControls") {
            saturationFilter.setValue(result, forKey: kCIInputImageKey)
            saturationFilter.setValue(0.85, forKey: kCIInputSaturationKey) // Slightly desaturated
            saturationFilter.setValue(1.08, forKey: kCIInputContrastKey) // Increased contrast
            saturationFilter.setValue(-0.05, forKey: kCIInputBrightnessKey) // Slightly darker
            if let output = saturationFilter.outputImage {
                result = output
            }
        }

        // Add warmth
        if let temperatureFilter = CIFilter(name: "CITemperatureAndTint") {
            temperatureFilter.setValue(result, forKey: kCIInputImageKey)
            temperatureFilter.setValue(CIVector(x: 6800, y: 0), forKey: "inputNeutral") // Warmer
            temperatureFilter.setValue(CIVector(x: 6500, y: -50), forKey: "inputTargetNeutral")
            if let output = temperatureFilter.outputImage {
                result = output
            }
        }

        // Enhance shadows and highlights for that film look
        if let toneCurveFilter = CIFilter(name: "CIToneCurve") {
            toneCurveFilter.setValue(result, forKey: kCIInputImageKey)
            toneCurveFilter.setValue(CIVector(x: 0, y: 0.05), forKey: "inputPoint0") // Lifted blacks
            toneCurveFilter.setValue(CIVector(x: 0.25, y: 0.22), forKey: "inputPoint1")
            toneCurveFilter.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
            toneCurveFilter.setValue(CIVector(x: 0.75, y: 0.78), forKey: "inputPoint3")
            toneCurveFilter.setValue(CIVector(x: 1, y: 0.98), forKey: "inputPoint4") // Compressed highlights
            if let output = toneCurveFilter.outputImage {
                result = output
            }
        }

        return result
    }

    // Velvia: Vibrant, saturated colors - great for food photography
    private func applyVelvia(to image: CIImage) -> CIImage {
        var result = image

        // Boost saturation and contrast
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(result, forKey: kCIInputImageKey)
            colorFilter.setValue(1.25, forKey: kCIInputSaturationKey) // High saturation
            colorFilter.setValue(1.15, forKey: kCIInputContrastKey)
            if let output = colorFilter.outputImage {
                result = output
            }
        }

        // Enhance reds and greens (typical Velvia look)
        if let vibranceFilter = CIFilter(name: "CIVibrance") {
            vibranceFilter.setValue(result, forKey: kCIInputImageKey)
            vibranceFilter.setValue(0.5, forKey: kCIInputAmountKey)
            if let output = vibranceFilter.outputImage {
                result = output
            }
        }

        return result
    }

    // Provia: Balanced, natural colors
    private func applyProvia(to image: CIImage) -> CIImage {
        var result = image

        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(result, forKey: kCIInputImageKey)
            colorFilter.setValue(1.05, forKey: kCIInputSaturationKey)
            colorFilter.setValue(1.05, forKey: kCIInputContrastKey)
            if let output = colorFilter.outputImage {
                result = output
            }
        }

        return result
    }

    // Astia: Soft, pastel-like colors
    private func applyAstia(to image: CIImage) -> CIImage {
        var result = image

        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(result, forKey: kCIInputImageKey)
            colorFilter.setValue(0.95, forKey: kCIInputSaturationKey)
            colorFilter.setValue(0.95, forKey: kCIInputContrastKey)
            colorFilter.setValue(0.05, forKey: kCIInputBrightnessKey) // Slightly brighter
            if let output = colorFilter.outputImage {
                result = output
            }
        }

        return result
    }

    // Add subtle film grain for authenticity
    private func addFilmGrain(to image: CIImage) -> CIImage {
        guard let grainFilter = CIFilter(name: "CIRandomGenerator"),
              let grainOutput = grainFilter.outputImage else {
            return image
        }

        // Create grain effect
        let grainTransformed = grainOutput
            .transformed(by: CGAffineTransform(scaleX: 1.5, y: 1.5))
            .cropped(to: image.extent)

        // Blend grain with original image
        guard let blendFilter = CIFilter(name: "CISourceOverCompositing") else {
            return image
        }

        // Apply grain filter with low opacity
        let opacity: CGFloat = 0.08
        guard let colorMatrixFilter = CIFilter(name: "CIColorMatrix") else {
            return image
        }

        colorMatrixFilter.setValue(grainTransformed, forKey: kCIInputImageKey)
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: opacity), forKey: "inputAVector")

        guard let transparentGrain = colorMatrixFilter.outputImage else {
            return image
        }

        blendFilter.setValue(transparentGrain, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)

        return blendFilter.outputImage ?? image
    }
}
