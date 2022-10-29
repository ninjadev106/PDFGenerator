//
//  ViewController.swift
//  testPDFGenerator
//
//  Created by ninjadev on 10/28/22.
//

import UIKit
import PDFKit

// Mock data
let labels: [[String]] = [
    ["Lockout / Tag out required", "Hot Work Permit Required", "Other Permits Required", "Proper Notifications Made"],
    ["Body position / Lifting", "Pinch Points Concerns", "Walking Working Surfaces", "Line of Fire Concerns", "Additional PPE Required"],
    ["Other Work in Area of Concern", "Weather / Driving Concerns", "Housekeeping Concerns", "Emergency Actions Identified"]
]
let strIsCheckeds: [[String]] = [
    ["Yes", "No", "Yes", "N/A"],
    ["Yes", "No", "Yes", "Yes", "No", "Yes"],
    ["Yes", "No", "Yes", "N/A"],
]
let categories = ["Procedure Consideration", "Hazards", "Environmental"]


struct RadioItem {
    let label: String
    let strIsChecked: String
    init(label: String, strIsChecked: String) {
        self.label = label
        self.strIsChecked = strIsChecked
    }
}

struct JSAItem {
    let date: String = ""
    let location: String = ""
    let siteemerg: String = ""
    let musterpoints: String = ""
    let workperformed: String = ""
    let description: String = ""
    let radioList: [String:[RadioItem]] = [:]
}

class ViewController: UIViewController {
    var pdfView: PDFView!

    override func viewDidLoad() {
        super.viewDidLoad()
        createUI()
        createPDF()
    }

    func createUI() {
        pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }

    func createPDF() {
        var radioList = JSAItem().radioList
        for catIndex in 0..<categories.count {
            var radioItems = [RadioItem]()
            for itemIndex in 0..<labels[catIndex].count {
                radioItems.append(RadioItem(label: labels[catIndex][itemIndex], strIsChecked: strIsCheckeds[catIndex][itemIndex]))
            }
            print("category:", categories[catIndex])
            radioList[categories[catIndex]] = radioItems
        }
        print("radioList:", radioList)
        let pdfCreator = PDFCreator(tableDataItems: radioList)

        let data = pdfCreator.create()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
    }

}

extension Array {
    func chunkedElements(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

class PDFCreator: NSObject {
    let defaultOffset: CGFloat = 14
    var tableData:[String:[RadioItem]] = [:]

    init(tableDataItems: [String:[RadioItem]]) {
        self.tableData = tableDataItems
    }

    func create() -> Data {
        // A4 Gabarit
        let pageWidth = 595.2
        let pageHeight = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: UIGraphicsPDFRendererFormat())

//        let numberOfElementsPerPage = calculateNumberOfElementsPerPage(with: pageRect)
//        let tableDataChunked: [[RadioItem]] = tableDataItems.chunkedElements(into: numberOfElementsPerPage)

        let data = renderer.pdfData { context in
            for (key, value) in tableData {
                let dataItems: [RadioItem] = value
                let headerTitles = [key, "Check all that apply"]
                context.beginPage()
                let cgContext = context.cgContext
                drawTableHeaderRect(drawContext: cgContext, pageRect: pageRect)
                drawTableHeaderTitles(titles: headerTitles, drawContext: cgContext, pageRect: pageRect)
                drawTableContentInnerBordersAndText(drawContext: cgContext, pageRect: pageRect, tableDataItems: dataItems)
            }
        }
        return data
    }

    func calculateNumberOfElementsPerPage(with pageRect: CGRect) -> Int {
        let rowHeight = (defaultOffset * 3)
        let number = Int((pageRect.height - rowHeight) / rowHeight)
        return number
    }
    
    
}

// Drawings
extension PDFCreator {
    func drawTableHeaderRect(drawContext: CGContext, pageRect: CGRect) {
        drawContext.saveGState()
        drawContext.setLineWidth(3.0)

        // Draw header's 1 top horizontal line
        drawContext.move(to: CGPoint(x: defaultOffset, y: defaultOffset))
        drawContext.addLine(to: CGPoint(x: pageRect.width - defaultOffset, y: defaultOffset))
        drawContext.strokePath()

        // Draw header's 1 bottom horizontal line
        drawContext.move(to: CGPoint(x: defaultOffset, y: defaultOffset * 3))
        drawContext.addLine(to: CGPoint(x: pageRect.width - defaultOffset, y: defaultOffset * 3))
        drawContext.strokePath()

        // Draw header's 3 vertical lines
        drawContext.setLineWidth(2.0)
        drawContext.saveGState()
        let tabWidth = (pageRect.width - defaultOffset * 2) / CGFloat(2)
        for verticalLineIndex in 0..<3 {
            let tabX = CGFloat(verticalLineIndex) * tabWidth
            drawContext.move(to: CGPoint(x: tabX + defaultOffset, y: defaultOffset))
            drawContext.addLine(to: CGPoint(x: tabX + defaultOffset, y: defaultOffset * 3))
            drawContext.strokePath()
        }
        drawContext.setFillColor(UIColor.red.cgColor)
        drawContext.restoreGState()
        
    }

    func drawTableHeaderTitles(titles: [String], drawContext: CGContext, pageRect: CGRect) {
        // prepare title attributes
        let textFont = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        let titleAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: textFont
        ]

        // draw titles
        let tabWidth = (pageRect.width - defaultOffset * 2) / CGFloat(2)
        for titleIndex in 0..<titles.count {
            let attributedTitle = NSAttributedString(string: titles[titleIndex].capitalized, attributes: titleAttributes)
            let tabX = CGFloat(titleIndex) * tabWidth
            let textRect = CGRect(x: tabX + defaultOffset,
                                  y: defaultOffset * 3 / 2,
                                  width: tabWidth,
                                  height: defaultOffset * 2)
            attributedTitle.draw(in: textRect)
        }
    }

    func drawTableContentInnerBordersAndText(drawContext: CGContext, pageRect: CGRect, tableDataItems: [RadioItem]) {
        drawContext.setLineWidth(1.0)
        drawContext.saveGState()

        let defaultStartY = defaultOffset * 3

        for elementIndex in 0..<tableDataItems.count {
            let yPosition = CGFloat(elementIndex) * defaultStartY + defaultStartY

            // Draw content's elements texts
            let textFont = UIFont.systemFont(ofSize: 13.0, weight: .regular)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byWordWrapping
            let textAttributes = [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: textFont
            ]
            let tabWidth = (pageRect.width - defaultOffset * 2) / CGFloat(2)
            for titleIndex in 0..<2 {
                var attributedText = NSAttributedString(string: "", attributes: textAttributes)
                let tabX = CGFloat(titleIndex) * tabWidth
                let textRect = CGRect(x: tabX + defaultOffset,
                                      y: yPosition + defaultOffset,
                                      width: tabWidth,
                                      height: defaultOffset * 2)
                switch titleIndex {
                case 0:
                    attributedText = NSAttributedString(string: tableDataItems[elementIndex].label, attributes: textAttributes)
                case 1:
                    attributedText = NSAttributedString(string: tableDataItems[elementIndex].strIsChecked, attributes: textAttributes)
                default:
                    break
                }
                attributedText.draw(in: textRect)
            }

            // Draw content's 3 vertical lines
            for verticalLineIndex in 0..<3 {
                let tabX = CGFloat(verticalLineIndex) * tabWidth
                drawContext.move(to: CGPoint(x: tabX + defaultOffset, y: yPosition))
                drawContext.addLine(to: CGPoint(x: tabX + defaultOffset, y: yPosition + defaultStartY))
                drawContext.strokePath()
            }

            // Draw content's element bottom horizontal line
            drawContext.move(to: CGPoint(x: defaultOffset, y: yPosition + defaultStartY))
            drawContext.addLine(to: CGPoint(x: pageRect.width - defaultOffset, y: yPosition + defaultStartY))
            drawContext.strokePath()
        }
        drawContext.restoreGState()
    }
}
